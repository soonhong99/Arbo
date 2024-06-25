const {GoogleGenerativeAI} = require("@google/generative-ai");
const dotenv = require("dotenv")
dotenv.config()
const readline = require("readline")
// Access your API key as an environment variable (see "Set up your API key" above)
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const userInterface = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

// user가 프롬프트에 원하는 것을 입력할 수 있도록 해주는 코드
userInterface.prompt()

userInterface.on("line", async input => {
  // The Gemini 1.5 models are versatile and work with both text-only and multimodal prompts
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash"});


  // 빠르게 reponse 받는 방법
  // const result = await model.generateContentStream([input]);
  // for await (const chunk of result.stream) {
  //   const chunkText = chunk.text();
  //   console.log(chunkText)
  // }
  
  const result = await model.generateContent(input);
  const response = await result.response;
  const text = response.text();
  console.log(text);

})
