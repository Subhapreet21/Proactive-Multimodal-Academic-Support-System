# Proactive Multimodal Academic Support System
## Project Documentation & Report

**Table of Contents**

*   **Chapter 1: Introduction**
    *   1.1 Introduction
    *   1.2 Problem Statement
    *   1.3 Objective of Project
    *   1.4 Goal of Project
    *   1.5 Project Scope
    *   1.6 Limitations
*   **Chapter 2: Problem Identification & Analysis**
    *   2.1 Existing System Analysis
    *   2.2 Literature Survey
    *   2.3 Proposed System
*   **Chapter 3: Requirements Analysis**
    *   3.1 Software Requirements
    *   3.2 Hardware Requirements
    *   3.3 Functional Requirements (Module-wise)
    *   3.4 Non-Functional Requirements
*   **Chapter 4: System Design**
    *   4.1 System Architecture
    *   4.2 UML Diagrams
    *   4.3 Database Design (Schema)
*   **Chapter 5: Implementation & Code**
    *   5.1 SDLC Methodology
    *   5.2 Source Code Structure
    *   5.3 Key Source Code & Analysis
    *   5.4 Algorithm Analysis (RAG)
*   **Chapter 6: Testing, Results & Conclusion**
    *   6.1 Testing Methodologies
    *   6.2 Test Cases & Results
    *   6.3 Conclusion
    *   6.4 Future Enhancements

---

# Chapter 1: Introduction

## 1.1 Introduction
The education sector is undergoing a massive digital transformation, moving away from traditional, paper-based administrative processes towards integrated smart campus solutions. The **Proactive Multimodal Academic Support System (Campus Assistant)** is a pioneering initiative designed to modernize the university experience by leveraging the latest advancements in **Mobile Computing**, **Cloud Infrastructure**, and **Artificial Intelligence (Generative AI)**.

In a typical university environment, stakeholders (students, faculty, and administrators) operate in silos. Information is often fragmented across physical notice boards, legacy web portals, disparate email threads, and informal social media groups. This fragmentation leads to communication gaps, administrative inefficiencies, and a disjointed user experience.

This project addresses these challenges by creating a **Unified Digital Ecosystem**. Built upon the robust **Flutter** framework for cross-platform mobile access and powered by **Google Gemini AI**, the system offers a cohesive interface for all academic needs. It moves beyond simple digitization by alerting users *proactively*—reminding students of upcoming deadlines, notifying faculty of schedule clashes, and guiding visitors through an interactive 3D virtual tour.

## 1.2 Problem Statement
Despite the availability of various digital tools, the academic environment continues to face persistent challenges:
1.  **Information Asymmetry & Fragmentation**: Critical updates regarding exam schedules, venue changes, or emergency notices are often posted on physical boards or buried in email threads, leading to students missing vital information.
2.  **Lack of Personalized, 24/7 Support**: Students often have repetitive queries regarding syllabus verification, lab timings, or administrative procedures. Administrative offices operate during fixed hours and cannot handle the volume of redundant queries, leading to long wait times and frustration.
3.  **Static & Confusing Navigation**: University campuses are often sprawling and complex. New students and visitors struggle to navigate using generic 2D maps, which lack context and real-time guidance.
4.  **Inefficient Resource Management**: Faculty and administrators spend a disproportionate amount of time on manual scheduling and conflict resolution, detracting from their core educational responsibilities.

## 1.3 Objective of Project
The primary objectives of this project are multi-faceted, aiming to solve technological and operational problems:
*   **Centralization**: To develop a single, robust mobile platform that aggregates all academic, administrative, and co-curricular information, eliminating the need for multiple disjointed apps.
*   **Intelligent Automation**: To implement an **AI-powered assistant** capable of Natural Language Understanding (NLU). This assistant serves as a "first-line responder" for student queries, using RAG (Retrieval-Augmented Generation) to provide accurate answers cited from the official university handbook.
*   **Immersive Navigation**: To provide an **interactive 3D Virtual Tour** of the campus, allowing users to virtually explore facilities, locate classrooms, and understand the campus layout remotely.
*   **Real-time Synchronization**: To enable instant updates for timetables and notices. A change made by an administrator should reflect on a student's device within milliseconds, ensuring everyone is on the same page.
*   **Role-Based Security & Personalization**: To ensure that the system adapts to the user. A student sees their specific classes, while a faculty member sees their teaching load, secured by robust authentication policies.

## 1.4 Goal of Project
The ultimate goal is to deploy a scalable, robust, and user-friendly "Smart Campus" solution that serves as a blueprint for modern educational institutions. This system aims to:
*   **Reduce Administrative Overhead** by automating routine queries.
*   **Improve Student Satisfaction** by providing instant access to information.
*   **Enhance Campus Safety and Accessibility** through better navigation and communication channels.
*   **Modernize Institutional Infrastructure** to align with Industry 4.0 standards.

## 1.5 Project Scope
*   **In-Scope**:
    *   Mobile Application Development (Android/iOS).
    *   AI Chatbot integration with RAG.
    *   Role-based dashboards (Admin, Faculty, Student).
    *   Real-time database updates for Timetable/Notices.
    *   360-degree Virtual Tour viewer.
*   **Out-of-Scope**:
    *   Payment Gateway integration (Fee collection).
    *   Biometric hardware integration.
    *   Full-scale Learning Management System (LMS) features like assignment submission (planned for V2).

## 1.6 Limitations
1.  **Internet Dependency**: The app requires an active internet connection to fetch real-time data and perform AI inference.
2.  **API Rate Limits**: The current free-tier usage of Google Gemini API restricts the number of concurrent AI queries (compensated via Load Balancing).
3.  **Device Hardware**: The 3D Virtual Tour requires devices with Gyroscope sensors; older budget phones may experience lag.

---

# Chapter 2: Problem Identification & Analysis

## 2.1 Existing System Analysis
The current operational model in most institutions relies heavily on "analog" or "legacy digital" methods. While functional, these systems suffer from significant latency and lack of integration.

*   **Manual Timetables**: Timetables are often created in Excel and printed out. Changes require re-printing or circulating new files via WhatsApp, leading to version control issues.
*   **Physical Dependencies**: To read important circulars, students must physically be present near the notice board. To pay fees or get a bona fide certificate, they must physically visit the admin block.
*   **Static Web Portals**: University websites are typically repositories of static information. They are rarely mobile-optimized and do not offer personalized views.
*   **Human-Dependent Support**: Queries regarding specific lab equipment usage or library book availability require finding the right staff member, which is not always possible.

## 2.2 Literature Survey
A comprehensive analysis of existing solutions was conducted to identify gaps.

| Feature | Google Classroom | Moodle (LMS) | University Website | **Proposed System** |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Focus** | Assignment/Content | Course Management | Static Information | **Holistic Campus Life** |
| **Real-time Updates** | Moderate (Email) | Low | Low | **High (Push/Sockets)** |
| **AI Assistant** | No | No (Plugin required) | No | **Yes (Gemini RAG)** |
| **Campus Nav** | No | No | 2D Maps | **3D Virtual Tour** |
| **Mobile UX** | Good | Generic/Web-view | Poor | **Native (Flutter)** |
| **Personalization** | Class-based | Course-based | None | **Role & Context-based** |

## 2.3 Proposed System
The **Proactive Multimodal Academic Support System** introduces a paradigm shift towards a "Digital First" campus. It is designed around the needs of the modern digital native student.
*   **Dynamic Dashboard**: Upon login, the user is greeted with a personalized dashboard. A sophisticated algorithm determines the "Next Class" based on the current time and the user's section, displaying it prominently.
*   **Context-Aware AI Chatbot**: Unlike generic chatbots, our Gemini-powered assistant has "long-term memory" of the campus context. It knows that "Lab 3" refers to the "Computer Networks Lab" in "Block B", thanks to vector embedding technology.
*   **Virtual Tour**: A 360-degree panoramic view of key campus locations (Library, Labs, Auditorium) allows users to explore the campus from their smartphone. Gyroscopic sensors allow for an immersive "look around" experience.
*   **Cloud-Native Infrastructure**: All data (timetables, events, profiles) is stored in Supabase, a scalable cloud database. This ensures high availability and allows for instant synchronization across thousands of concurrent users.

---

# Chapter 3: Requirements Analysis

## 3.1 Software Requirements
The project is constructed using a carefully selected stack of modern technologies, ensuring cross-platform compatibility, security, and scalability.

*   **Mobile Framework**: **Flutter (Dart)** - Version 3.x+
*   **Backend Runtime**: **Node.js (TypeScript)** - Version 20 LTS
*   **Web Framework**: **Express.js**
*   **Database**: **Supabase (PostgreSQL 15)** with `pgvector` extension.
*   **AI Services**: **Google Gemini API** (`gemini-2.5-flash`, `gemini-embedding-001`).
*   **IDE**: Visual Studio Code, Android Studio.
*   **Design Tools**: Figma (UI), Blender (3D).
*   **Deployment**: Render (Backend), Vercel (Web), Google Play Store (App).

## 3.2 Hardware Requirements
*   **Development Server**: 
    *   CPU: 2 vCPU minimum.
    *   RAM: 4GB RAM minimum.
    *   Network: 100 Mbps uplink.
*   **Client Device (Mobile)**:
    *   **OS**: Android 10.0+ / iOS 14+.
    *   **RAM**: 4GB recommended.
    *   **Sensors**: Accelerometer, Gyroscope, Magnetometer.

## 3.3 Functional Requirements (Module-wise)

### 3.3.1 Student Module
*   **FR-S-01**: View personalized "Next Class" widget.
*   **FR-S-02**: Access full weekly timetable.
*   **FR-S-03**: Chat with AI Assistant for academic queries.
*   **FR-S-04**: View and filter Announcements/Events.
*   **FR-S-05**: Access 3D Virtual Tour.
*   **FR-S-06**: Receive push notifications for schedule changes.

### 3.3.2 Faculty Module
*   **FR-F-01**: View teaching schedule.
*   **FR-F-02**: Look up student details (restricted view).
*   **FR-F-03**: Post class-specific announcements.
*   **FR-F-04**: Use AI Co-Pilot to generate Lecture Plans.

### 3.3.3 Admin Module
*   **FR-A-01**: Manage Users (Create/Delete Accounts).
*   **FR-A-02**: Global Timetable Management (Edit Slots).
*   **FR-A-03**: Post Global Notices (Holiday, Emergencies).
*   **FR-A-04**: Manage Knowledge Base for AI.

## 3.4 Non-Functional Requirements
1.  **NFR-01 Scalability**: The database schema must support 10,000+ users and 500,000+ timetable rows without performance degradation.
2.  **NFR-02 Reliability**: The system must maintain 99.9% uptime during university working hours (8 AM - 6 PM).
3.  **NFR-03 Security**: All API endpoints must be protected via JWT. Passwords must be hashed using bcrypt.
4.  **NFR-04 Latency**: AI responses must be generated within 3 seconds; Dashboard load time under 1 second.
5.  **NFR-05 Usability**: The application adheres to Material Design 3 guidelines for high accessibility.

---

# Chapter 4: System Design

## 4.1 System Architecture
The system utilizes a **Service-Oriented Architecture (SOA)**, decoupling the frontend from the backend services.

*   **Client Layer**: Flutter Application (Android/iOS). Handles UI, Local Storage (Hive), and State Management (Provider/BLoC).
*   **Gateway Layer**: Node.js Express API. Serves as the central entry point, handling Routing, Auth Middleware, and Rate Limiting.
*   **Service Layer**:
    *   **AI Service**: Manages Gemini API keys and Embedding generation.
    *   **Timetable Service**: Handles complex SQL queries for scheduling.
    *   **Notification Service**: Manages FCM (Firebase Cloud Messaging).
*   **Data Layer**: Supabase.
    *   **Auth**: Manages Users and Sessions.
    *   **Postgres**: Relational Data.
    *   **Storage**: Images/Assets for Virtual Tour.

## 4.2 UML Diagrams

### 4.2.1 Use Case Diagram
```mermaid
graph LR
    Student((👤 Student))
    Faculty((👨‍🏫 Faculty))
    Admin((🛡️ Admin))

    subgraph "Campus Assistant Ecosystem"
        direction TB
        %% Common
        UC_Login(Login via Supabase Auth)
        UC_Dash(View Smart Dashboard)
        UC_Chat(Chat with Gemini AI)
        UC_Tour(Virtual Campus Tour)
        
        %% Student Specific
        UC_MySchedule(View My Timetable)
        UC_Events(View Events & Notices)
        
        %% Faculty Specific
        UC_DeptSchedule(View Dept Timetable)
        UC_CreateNotice(Post Articles)
        
        %% Admin Specific
        UC_ManageUsers(Manage Users & Roles)
        UC_ManageKB(Manage AI Knowledge Base)
        UC_GlobalTimetable(Manage Global Timetable)
    end

    Student --> UC_Login & UC_Dash & UC_Chat & UC_Tour & UC_MySchedule & UC_Events
    Faculty --> UC_Login & UC_Dash & UC_Chat & UC_DeptSchedule & UC_CreateNotice
    Admin --> UC_Login & UC_Dash & UC_Chat & UC_ManageUsers & UC_ManageKB & UC_GlobalTimetable
```

### 4.2.2 Sequence Diagram (AI Chat Flow with RAG)
```mermaid
sequenceDiagram
    participant User as 👤 User
    participant App as 📱 Flutter App
    participant API as ⚙️ Express API
    participant AI as 🧠 Gemini API
    participant DB as 💾 Supabase

    User->>App: "What's my next class?"
    App->>API: POST /chat (msg, history)
    
    note right of API: Step 1: Context Retrieval
    API->>AI: Generate Embedding (text-embedding-001)
    AI-->>API: Vector[3072]
    API->>DB: RPC match_kb_articles(vector)
    DB-->>API: Relevant KB Articles
    API->>DB: Fetch User Timetable/Reminders
    DB-->>API: User Context
    
    note right of API: Step 2: Generation
    API->>API: Construct System Prompt
    API->>AI: Generate Content (gemini-2.5-flash)
    AI-->>API: "Your next class is Math at 2 PM"
    
    API-->>App: JSON Response
    App->>User: Display Answer
```

### 4.2.3 Deployment Diagram
```mermaid
graph TD
    subgraph Client ["📱 Client Device"]
        Flutter[Flutter App]
        LocalDB[(Hive Local Storage)]
        Flutter --> LocalDB
    end
    
    subgraph Cloud ["☁️ Backend Infrastructure"]
        API[Node.js Express API]
        
        subgraph Services
            Supabase[Supabase Platform]
            Gemini[Google Gemini AI]
        end
        
        subgraph Database
            Postgres[(PostgreSQL DB)]
            Vector[(pgvector Extension)]
            Auth[(Supabase Auth)]
            Storage[(Object Storage)]
        end
    end

    Flutter -- HTTPS/REST --> API
    API -- "TCP/IP (Pool)" --> Postgres
    API -- HTTPS --> Gemini
    Postgres <--> Vector
    Supabase -- Manage --> Auth & Storage & Postgres
```

### 4.2.4 Activity Diagram (AI Chat Logic)
```mermaid
flowchart TD
    Start([User Sends Message]) --> CheckType{Message Type?}
    
    %% Image Handling
    CheckType -- Image --> ProcessImage[Process with Gemini Vision]
    ProcessImage --> GenerateImgResp[Generate Description/Answer]
    
    %% Text Handling
    CheckType -- Text --> DetectIntent{Intent Analysis}
    
    %% Intent Branches
    DetectIntent -- "Next Class?" --> CheckDay{Is Today Sunday?}
    CheckDay -- Yes --> FetchMonday[Fetch Monday's Timetable]
    CheckDay -- No --> FetchToday[Fetch Today's Timetable]
    FetchMonday & FetchToday --> ContextBuilder
    
    DetectIntent -- "Rules/Regs" --> FetchAllRules[Fetch Top 30 KB Articles]
    FetchAllRules --> ContextBuilder
    
    DetectIntent -- General Query --> EmbedMsg[Generate Embedding]
    EmbedMsg --> VectorSearch[Vector Search Supabase]
    VectorSearch --> ContextBuilder
    
    contextBuilder[Context Builder] --> SystemPrompt[Construct System Prompt]
    SystemPrompt --> Gemini[Call Gemini 2.5 API]
    Gemini --> Validate{Response Valid?}
    Validate -- Yes --> SendResp([Send Response to User])
    Validate -- No --> Retry[Retry / Error Msg]
```

## 4.3 Database Design (Schema)

```mermaid
erDiagram
    profiles ||--o{ timetables : "has schedule"
    profiles ||--o{ reminders : "sets"
    profiles ||--o{ events_notices : "creates (faculty/admin)"
    profiles ||--o{ kb_articles : "authors (admin)"
    
    kb_articles ||--o{ kb_embeddings : "has vectors"
    
    profiles {
        uuid id PK
        text email
        text full_name
        text role "admin/faculty/student"
        text department
        text year
        text section
    }

    timetables {
        uuid id PK
        uuid user_id FK
        text day_of_week
        time start_time
        time end_time
        text course_name
        text location
    }

    reminders {
        uuid id PK
        uuid user_id FK
        text title
        timestamp due_at
        boolean is_completed
    }

    events_notices {
        uuid id PK
        text title
        text description
        timestamp event_date
        uuid created_by FK
    }

    kb_articles {
        uuid id PK
        text title
        text content
        uuid author_id FK
    }

    kb_embeddings {
        uuid id PK
        uuid article_id FK
        vector embedding
    }
    
    invitation_codes {
        text code PK
        text role
        int usage_limit
        int used_count
    }
```

# Chapter 5: Implementation & Code

## 5.1 SDLC Methodology
We adopted the **Agile Methodology** for this project.
*   **Sprints**: 2-week development cycles.
*   **Iterative Design**: Constant feedback loop from initial prototypes to final UI.
*   **CI/CD**: Continuous Integration via GitHub Actions to ensure code stability.

## 5.2 Source Code Structure
```
/
├── flutter_app/          # Mobile Frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/      # Dashboard, Chat, Profile
│   │   ├── services/     # API, Auth
│   │   └── widgets/      # UI Components
│
└── backend/              # Node.js API
    ├── src/
    │   ├── index.ts
    │   ├── controllers/  # Logic
    │   └── services/     # Integrations
```

## 5.3 Key Source Code & Analysis

### 5.3.1 AI Service (Load Balancing)
**Analysis**: To improve reliability, we implemented a round-robin key rotation system for Gemini API.
```typescript
// backend/src/services/aiService.ts
const executeWithRetry = async <T>(operation: (genAI: GoogleGenerativeAI) => Promise<T>): Promise<T> => {
    const shuffledKeys = [...apiKeys].sort(() => Math.random() - 0.5);
    for (const key of shuffledKeys) {
        try {
            return await operation(new GoogleGenerativeAI(key));
        } catch (error) {
            console.warn(`Key failed, retrying...`);
        }
    }
    throw new Error("All keys failed");
};
```

### 5.3.2 RAG Controller
**Analysis**: Incorporates Vector Search to fetch context before generating answers.
```typescript
// backend/src/controllers/chatController.ts
export const handleTextChat = async (req, res) => {
    // 1. Get Embedding
    const embedding = await getEmbedding(req.body.message);
    // 2. Search DB
    const { data: context } = await supabase.rpc('match_kb_articles', { query_embedding: embedding });
    // 3. Generate Answer
    const response = await generateText(req.body.message, JSON.stringify(context));
    res.json({ response });
};
```

## 5.4 Algorithm Analysis (RAG)
The core of the AI assistant uses **Retrieval-Augmented Generation (RAG)**.
1.  **Vectorization**: User query $Q$ is converted to a vector $V_q$ using `gemini-embedding-001`.
2.  **Similarity Search**: We calculate the **Cosine Similarity** between $V_q$ and all stored Knowledge Base vectors $V_{kb}$.
    $$ \text{similarity} = \frac{V_q \cdot V_{kb}}{\|V_q\| \|V_{kb}\|} $$
3.  **Ranking**: Articles with similarity score > 0.3 are retrieved as context.

---

# Chapter 6: Testing, Results & Conclusion

## 6.1 Testing Methodologies
*   **Unit Testing**: Jest (Backend) and Flutter Test (Frontend) for individual functions.
*   **Integration Testing**: Postman to verify API-Database interaction.
*   **User Acceptance Testing (UAT)**: Beta testing with 5 students and 2 faculty members.

## 6.2 Test Cases & Results

| ID | Module | Test Case | Expected | Result |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | **Auth** | Login with invalid email | Show "User not found" | **PASS** |
| **TC-02** | **Auth** | Login with correct credentials | Redirect to Dashboard | **PASS** |
| **TC-03** | **Dashboard** | Load without internet | Show Cached Data/Error | **PASS** |
| **TC-04** | **AI** | Query about Exam date | Retrieve correct date from KB | **PASS** |
| **TC-05** | **AI** | Irrelevant Query | Fallback to general knowledge | **PASS** |
| **TC-06** | **Timetable** | Faculty updates slot | Student sees update in <1s | **PASS** |
| **TC-07** | **Tour** | Rapid pan/tilt | No jitter in 3D view | **PASS** |
| **TC-08** | **Security** | Access Admin API as Student | Return 403 Forbidden | **PASS** |
| **TC-09** | **Profile** | Logout | Clear session token | **PASS** |
| **TC-10** | **Load** | 50 concurrent requests | API latency < 500ms | **PASS** |

## 6.3 Conclusion
The **Proactive Multimodal Academic Support System** successfully demonstrates the transformative potential of combining AI, Mobile Cloud, and 3D technologies in an educational setting. By replacing disjointed legacy systems with a unified, intelligent platform, we have significantly:
*   **Democratized Access**: Information is now available to every student, 24/7.
*   **Optimized Operations**: Faculty spend less time on administration.
*   **Modernized Experience**: The campus now feels "Smart" and connected.

## 6.4 Future Enhancements
1.  **Augmented Reality (AR)**: Overlaying class details on the camera view.
2.  **Voice Interaction**: Full duplex voice conversation with the AI.
3.  **Offline Support**: Syncing critical data for offline access.
4.  **Analytics Dashboard**: Insights on student query trends for Admin.
