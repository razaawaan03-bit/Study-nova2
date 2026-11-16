# Privacy Policy — Study Nova

**Status: PLACEHOLDER. This text must be reviewed and completed by the app
owner, and the contact details filled in, before the app is published to Google
Play or the web. Do not publish this placeholder as-is.**

_Last updated: replace with the date you publish._

## 1. Who we are

Study Nova is a study application developed by **<your name or company>**.
Our contact email is **<your support email address>**.

## 2. What Study Nova does

Study Nova helps students study. A student can:

- take or choose a photo of study material and receive an AI explanation, a
  mind map and a quiz;
- upload study documents (PDF, Word, PowerPoint) and images to build a course;
- read bundled lessons and quizzes in Study Nova Labs;
- create a study mission that plans daily tasks.

## 3. What we collect

| Data | Why | Where it is stored |
| --- | --- | --- |
| Email address and password | To create and sign in to a study account | Supabase, in the account's own row (password is hashed by Supabase) |
| Name entered at sign-up | To greet the student | Supabase, with the account |
| Photos the student analyses | To generate the explanation, mind map and quiz | Supabase Storage, in a folder named with the account id |
| Uploaded documents and generated courses | To build and reopen a saved course | Supabase, in the account's own row |
| Study missions, Lab progress, quiz scores | To show the student their own progress | Supabase (missions) and on the device (Labs) |
| Device-generated crash and usage logs | To fix problems in the app | <describe your analytics/logging provider, or delete this row if you use none> |

We do **not** collect payment details, and Study Nova contains no advertising.

## 4. How we use the data

- The uploaded material is sent to Google Gemini to produce the explanation,
  mind map and quiz. **Only the material the student chose is sent.** No other
  account's data is ever sent.
- The account data is used to show the student their own courses, analyses and
  progress.

## 5. Who can see it

- Each student's data is stored under their own account. Supabase Row Level
  Security ensures one account can never read another account's data.
- Study Nova has no internal sharing between accounts.
- **<Delete or complete: name any third party with access, for example a
  developer or support contractor, and the legal basis for it.>**

## 6. How long we keep it

We keep a student's data until the student deletes it from the app or the
account is deleted. **<State the retention period for accounts that are never
used again.>**

## 7. Deleting your data

A student can delete an analysed photo or a saved course from inside the app.
To delete the whole account and all of its data, contact **<your support email
address>**. We will delete the account and its data within **<number of days>**
days.

## 8. Children

Study Nova is intended for students aged **<state the minimum age, for example
13, and whether you comply with COPPA or the GDPR/UK GDPR age rules>**. We do
not knowingly collect data from children below that age.

## 9. Security

Data is protected by Supabase Row Level Security and by the access controls on
the storage bucket. Access to the production database is limited to the project
owner.

## 10. Your rights

Depending on where you live, you may have the right to access, correct, export
or delete your personal data, and to object to how it is used. Contact
**<your support email address>** to make a request. If you are in the EU/UK you
can also complain to your local data protection authority.

## 11. Changes to this policy

If this policy changes, the new version will be published here with an updated
date, and the app's "Privacy Policy" link will point to it.
