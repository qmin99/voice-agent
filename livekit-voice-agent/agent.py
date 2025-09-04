import asyncio
import logging
from dotenv import load_dotenv
from livekit import agents
from livekit.agents import AgentSession, Agent, RoomInputOptions
from livekit.plugins import (
    groq,
    deepgram,
    noise_cancellation,
    silero,
)
from livekit.plugins.azure import TTS as AzureTTS
from livekit.plugins.turn_detector.multilingual import MultilingualModel

# Load environment variables
load_dotenv(".env.local")

# Set up logging
logger = logging.getLogger(__name__)

class HaakeemAssistant(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions="""You are  a professional AI legal assistant. You are knowledgeable, helpful, and speak in a clear, professional manner. 
            
Key guidelines:
- Provide accurate legal information but remind users you're not a substitute for professional legal advice
- Be concise but thorough in your responses
- Maintain a professional yet friendly tone
- If unsure about legal specifics, recommend consulting with a qualified attorney
- Help with contract reviews, legal document analysis, and general legal questions
            
Keep your responses conversational and avoid being overly verbose."""
        )

async def entrypoint(ctx: agents.JobContext):
    """Main entrypoint for the agent"""
    session = None
    agent = None
    
    try:
        logger.info(f"Starting HAAKEEM for room: {ctx.room.name}")
        
        # Create agent instance
        agent = HaakeemAssistant()
        
        # Create session with only valid parameters
        session = AgentSession(
            stt=deepgram.STT(
                model="nova-3", 
                language="multi"
            ),
            llm=groq.LLM(
                model="llama-3.3-70b-versatile"
            ), 
            tts=AzureTTS(
                voice="en-US-DavisNeural",
                language="en-US"
            ),
            vad=silero.VAD.load(),
            turn_detection=MultilingualModel(),
        )
        
        # Start the session
        await session.start(
            room=ctx.room,
            agent=agent,
            room_input_options=RoomInputOptions(
                noise_cancellation=noise_cancellation.BVC(),
                close_on_disconnect=True,
            ),
        )
        
        # Wait for connection to stabilize
        await asyncio.sleep(1.0)
        
        # Send greeting
        try:
            await asyncio.wait_for(
                session.generate_reply(
                    instructions="Greet the user briefly as their AI legal assistant, and ask how you can help them today."
                ),
                timeout=10.0
            )
            logger.info("Greeting sent successfully")
        except asyncio.TimeoutError:
            logger.warning("Greeting timed out")
        except Exception as e:
            logger.warning(f"Greeting failed: {e}")
        
        # Wait for session to complete
        await session.aclose()
        
    except Exception as e:
        logger.error(f"Error in agent session: {e}")
        
    finally:
        # Clean up
        logger.info("Cleaning up agent session")
        
        if session:
            try:
                await session.aclose()
            except:
                pass
                
        # Force cleanup
        import gc
        gc.collect()
        
        logger.info("Agent session cleanup completed")

if __name__ == "__main__":
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))