import os
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
import google.generativeai as genai
import json

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-3.8-flash")

app = FastAPI()


class PlayerAction(BaseModel):
    action_text: str


@app.post("/action")
def handle_action(player_action: PlayerAction):
    prompt = f"""You are a fantasy RPG Dungeon Master narrating a player's actions.

Player action: {player_action.action_text}

Respond with ONLY a valid JSON object, no markdown formatting, no code fences, no extra text before or after. Use exactly this structure:

{{
  "narration": "1-3 sentences of vivid narration describing what happens",
  "event": "one of: NONE, ENTER_AREA, COMBAT_START, ITEM_FOUND, NPC_REACTION, VILLAGE_ATTACKED, VILLAGE_SAVED",
  "quest_update": null,
  "relationship_changes": [],
  "items_added": [],
  "items_removed": []
}}

If the action reveals an item, set "event" to "ITEM_FOUND" and add an item name string to "items_added".
If nothing special happens mechanically, use "event": "NONE" and leave the arrays empty."""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    # Gemini sometimes wraps JSON in markdown code fences despite instructions — strip them if present
    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        structured_response = json.loads(raw_text)
    except json.JSONDecodeError:
        structured_response = {
            "narration": raw_text,
            "event": "NONE",
            "quest_update": None,
            "relationship_changes": [],
            "items_added": [],
            "items_removed": [],
        }

    return structured_response


class NPCDialogueRequest(BaseModel):
    npc_id: str
    personality: list[str]
    memories: list[str]
    player_message: str


@app.post("/npc_dialogue")
def handle_npc_dialogue(req: NPCDialogueRequest):
    personality_str = ", ".join(req.personality) if req.personality else "neutral"
    memories_str = "; ".join(req.memories) if req.memories else "No prior interactions."

    prompt = f"""You are roleplaying as an NPC in a fantasy RPG.

NPC personality traits: {personality_str}
NPC's memories of the player: {memories_str}

The player says to you: "{req.player_message}"

Respond with ONLY a valid JSON object, no markdown, no extra text:

{{
  "dialogue": "1-2 sentences of what the NPC says back, in character, informed by their personality and memories",
  "relationship_change": 0
}}

"relationship_change" should be a small integer (-5 to +5) reflecting how this exchange affects the NPC's opinion of the player."""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        structured_response = json.loads(raw_text)
    except json.JSONDecodeError:
        structured_response = {"dialogue": raw_text, "relationship_change": 0}

    return structured_response


class QuestGenerationRequest(BaseModel):
    theme_hint: str = ""


@app.post("/generate_quest")
def generate_quest(req: QuestGenerationRequest):
    theme_part = (
        f" The quest should relate to: {req.theme_hint}." if req.theme_hint else ""
    )

    prompt = f"""You are a quest designer for a fantasy RPG.{theme_part}

Respond with ONLY a valid JSON object, no markdown, no extra text:

{{
  "id": "a short_snake_case_id",
  "title": "Quest Title",
  "description": "1-2 sentence quest description",
  "objectives": ["objective 1", "objective 2", "objective 3"],
  "reward_gold": 50
}}

Keep objectives to 2-4 items. reward_gold should be between 20 and 100."""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        quest_data = json.loads(raw_text)
    except json.JSONDecodeError:
        quest_data = None

    return {"quest": quest_data}


class EventGenerationRequest(BaseModel):
    location_context: str = "a small village"


@app.post("/generate_event")
def generate_event(req: EventGenerationRequest):
    prompt = f"""You are a game master creating a random event for a fantasy RPG.
Current location: {req.location_context}

Respond with ONLY a valid JSON object, no markdown, no extra text:

{{
  "title": "Short event name",
  "description": "1-2 sentences describing what happens",
  "event_type": "one of: AMBUSH, DISCOVERY, WEATHER, NPC_ARRIVAL, MINOR_HAZARD"
}}"""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        event_data = json.loads(raw_text)
    except json.JSONDecodeError:
        event_data = None

    return {"random_event": event_data}


class EncounterGenerationRequest(BaseModel):
    danger_level: str = "low"


@app.post("/generate_encounter")
def generate_encounter(req: EncounterGenerationRequest):
    prompt = f"""You are a game master creating a combat encounter for a fantasy RPG.
Danger level: {req.danger_level}

Respond with ONLY a valid JSON object, no markdown, no extra text:

{{
  "enemy_name": "Name of the enemy",
  "description": "1-2 sentences describing the enemy's appearance/behavior",
  "enemy_health": 30,
  "enemy_attack": 8
}}

enemy_health should be between 15-50 for low danger, 50-100 for medium, 100-200 for high.
enemy_attack should be between 3-8 for low danger, 8-15 for medium, 15-25 for high."""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        encounter_data = json.loads(raw_text)
    except json.JSONDecodeError:
        encounter_data = None

    return {"encounter": encounter_data}


class DirectorRequest(BaseModel):
    world_summary: str
    player_action: str


@app.post("/director_action")
def director_action(req: DirectorRequest):
    prompt = f"""You are the Dungeon Master directing an ongoing fantasy RPG campaign.
Here is everything you know about the world so far:

{req.world_summary}

The player now does this: {req.player_action}

Using the history above, decide what happens. If something from the player's past (a betrayal, a kindness, a quest, a relationship) is relevant, let it surface naturally in the narration — for example, a reputation for betrayal might mean someone recognizes the player on sight.

Respond with ONLY a valid JSON object, no markdown, no extra text:

{{
  "narration": "2-4 sentences of narration, informed by the world history",
  "event": "one of: NONE, ENTER_AREA, COMBAT_START, ITEM_FOUND, NPC_REACTION, VILLAGE_ATTACKED, VILLAGE_SAVED",
  "callback_reference": "a short phrase naming which past event (if any) influenced this response, or null"
}}"""

    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        structured_response = json.loads(raw_text)
    except json.JSONDecodeError:
        structured_response = {
            "narration": raw_text,
            "event": "NONE",
            "callback_reference": None,
        }

    return structured_response
