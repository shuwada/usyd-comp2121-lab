U. of Sydney COMP2121: Cloud Computing Hands-On
=================================

I'm regularly invited to provide guest lectures on cloud computing at
University of New South Wales and University of Sydney - about few times a year.
It typically is a two or three hours talk in distributed computing course or
similar subjects.

This year I had the opportunity to give lectures involving hands-on: CS9243 in
U. of New South Wales and COMP2121 in U. of Sydney. When preparing for them, I've
looked up the Internet to search simple but practical hands-on material but it
turned out not many were available. So, I've created the material myself and
decided to open source it here.

The material in this repo is what I used at U. of Sydney. The lecture consisted
of a two-hour talk followed by one-hour hands-on session. To make the lecture
practical I used AWS as an example and discussed the details throughout the talk.
And, therefore, the hands-on session asked students to play with AWS.


Setup
------------

The great thing about AWS is they offer free usage credits for educators and
you can apply for it. But setting up an account for a course is bit tricky.
There are two ways to provide students access to AWS:

- Providing one AWS account for each student
- Sharing one AWS account with all students

One account per student is ideal since it gives perfect isolation between students
and they can do whatever they want. I took this approach in one course. Problem is
you need to create accounts for all students, i.e., create a new email address,
open AWS account, register a credit card (you cannot ask students to use their own
credit cards for the course), etc. It apparently does not scale.

There were 50 students in another course and I decided to go with the "one account
for all students" approach.

Here is what I did:

1. Create a new AWS account
1. Create an IAM user with minimum privilege. `iampolicy.txt' is the policy used in the course.
1. Create an AMI used in the course.
   Launch an Ubuntu instance, create a new user, copy `service.sh` and setup cron.

Students access to AWS web console or make API calls through the IAM user. What the user can do was
quite limited - the user cannot even terminate instances. But it is required for prevent mistakes
in the shared environment, e.g., deleting other students instances by mistake.

Files
-----------
- `iampolicy.txt` - IAM policy set for students account
- `service.sh` - A script installed in an AMI used in the course
- `dist` - All files in this directory were distributed to students

Note that the credentials in this repo had been revoked already. I just kept it for record.
