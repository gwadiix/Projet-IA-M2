import streamlit as st
import requests
import json

# Configuration
st.set_page_config(page_title="IA Assistant Client", page_icon="🤖")
st.title("🤖 Assistant IA Local (No-Docker)")

# URL de l'API Ollama locale
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "llama3.2:1b"

# Historique
if "messages" not in st.session_state:
    st.session_state.messages = []

# Affichage chat
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Zone de saisie
if prompt := st.chat_input("Posez votre question..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        message_placeholder = st.empty()
        full_response = ""
        
        # Appel à Ollama
        try:
            payload = {
                "model": MODEL_NAME,
                "prompt": prompt,
                "stream": False
            }
            response = requests.post(OLLAMA_URL, json=payload)
            if response.status_code == 200:
                data = response.json()
                full_response = data.get("response", "")
            else:
                full_response = f"Erreur API: {response.status_code}"
                
        except Exception as e:
            full_response = f"Erreur de connexion: {str(e)}"

        message_placeholder.markdown(full_response)
        st.session_state.messages.append({"role": "assistant", "content": full_response})