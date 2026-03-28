# Faculty Broadcast API: Study Resources & Notices

> **Base URL:** `https://campuspp-f7qx.onrender.com/api`
>
> All routes require a valid faculty or student JWT in the `Authorization` header.

---

## 1. Study Resources (Faculty Shared Material)

Faculty can share Images (JPEG/PNG/WEBP/GIF) or PDFs with all students in their institute. 
Files are stored securely in **Cloudinary**.

### 1.1 Upload Resource (Faculty only)
`POST /api/faculty-resources/upload`
- **Content-Type**: `multipart/form-data`
- **Fields**:
  - `file`: (Required) Max 20MB.
  - `title`: (Required, string)
  - `subject`: (Optional, string)
  - `description`: (Optional, string)

**Response `201`**
```json
{
  "success": true,
  "message": "Resource uploaded and notified students",
  "data": {
    "_id": "67abc...",
    "title": "Module 3 Notes",
    "subject": "AI",
    "fileUrl": "...",      
    "downloadUrl": "...",  
    "mimeType": "application/pdf",
    "fileSizeLabel": "1.2 MB",
    "facultyName": "Prof. Smith"
  }
}
```

### 1.2 Get Shared Resources (Student Dashboard)
`GET /api/student/resources`
- **Description**: Returns all resource cards shared by faculty in the student's institute.
- **Query Params**: `page`, `limit`, `subject`

---

## 2. Bulk Notices (Digital Notice Board)

Digital notice board alerts for high-priority institute-wide messages.

### 2.1 Send Broadcast Notice (Faculty only)
`POST /api/faculty-notices`
- **Body (`application/json`)**:
```json
{
  "title": "Mock Exam Tomorrow",
  "message": "The mock exam is scheduled at 10:00 AM. Attendance is mandatory.",
  "priority": "urgent",
  "tag": "exam"
}
```

### 2.2 Get Notices (Student Dashboard)
`GET /api/student/notices`
- **Description**: Reverse-chronological list of all bulk notices.

---

## 3. Real-Time Notifications for Dashboard

Broadcasts trigger instant in-app notifications with rich metadata for Flutter UI:

### 3.1 Metadata Sample (Resource Card)
```json
{
  "resourceId": "...",
  "fileUrl": "...",
  "downloadUrl": "...",
  "mimeType": "application/pdf",
  "isPdf": true,
  "title": "Course Syllabus",
  "fileSizeLabel": "245 KB"
}
```

### 3.2 Metadata Sample (Notice Card)
```json
{
  "noticeId": "...",
  "priority": "urgent",
  "tag": "exam",
  "facultyName": "Prof. Alan"
}
```
