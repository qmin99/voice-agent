import asyncio
import logging
from dotenv import load_dotenv
from livekit import agents
from livekit.agents import AgentSession, Agent, RoomInputOptions, AutoSubscribe, JobContext
from livekit.plugins import (
    groq,
    deepgram,
    noise_cancellation,
    silero,
)
from livekit.plugins.azure import TTS as AzureTTS

load_dotenv(".env.local")
logger = logging.getLogger(__name__)

class HaakeemAssistant(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions="""You are a professional AI legal assistant. Be concise and helpful."""
        )

async def entrypoint(ctx: JobContext):
    try:
        logger.info(f"Starting HAAKEEM for room: {ctx.room.name}")
        
        # Connect and wait for participant (CRITICAL!)
        await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
        participant = await ctx.wait_for_participant()
        logger.info(f"Starting voice assistant for participant {participant.identity}")
        
        agent = HaakeemAssistant()
        
        session = AgentSession(
            stt=deepgram.STT(model="nova-3", language="en"),
            llm=groq.LLM(model="llama-3.3-70b-versatile"), 
            tts=AzureTTS(voice="en-US-DavisNeural", language="en-US"),
            vad=silero.VAD.load(),
        )
        
        await session.start(
            room=ctx.room,
            agent=agent,
            room_input_options=RoomInputOptions(
                noise_cancellation=noise_cancellation.BVC(),
                close_on_disconnect=True,
            ),
        )
        
        # Send greeting and let session continue
        logger.info("Sending greeting...")
        await session.say("Hello! I'm your AI legal assistant. How can I help you today?")
        logger.info("Greeting sent successfully")
        
        # DON'T call session.aclose() - let it run indefinitely!
        
    except Exception as e:
        logger.error(f"Error in agent session: {e}")

if __name__ == "__main__":
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))