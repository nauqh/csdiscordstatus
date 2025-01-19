import streamlit as st
from code_editor import code_editor
import pandas as pd
import sqlite3


if 'selected_query' not in st.session_state:
    st.session_state.selected_query = ""

with open('script.sql', 'r') as f:
    scripts = f.read().split(';')
    scripts = [s.strip() for s in scripts if s.strip()]

st.set_page_config(
    page_title="Discord Status",
    page_icon="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTEk-hHEIFuICrkkzevJV3G5H3efaZWpO36NQ&s",
    layout="wide")
st.title("Discord Status")

st.image("schema.svg")


def update_query(script):
    st.session_state.selected_query = script


# Create buttons for each script
# Create a list of labels from the scripts
labels = [script.split('\n')[0].replace('--', '').strip()
          for script in scripts]

# Create a select box and update query when selection changes
selected_label = st.selectbox(
    "Select a query", labels, key="query_selector")
selected_index = labels.index(selected_label)
update_query(scripts[selected_index])

conn = sqlite3.connect('forum.db')
cursor = conn.cursor()

query = code_editor("-- Enter your query, hit Ctrl+Enter to run\n" + st.session_state.selected_query,
                    lang="sql",
                    height="500px",
                    theme="light")

if query['text']:
    df = pd.read_sql_query(query['text'], conn)
    st.dataframe(df)
