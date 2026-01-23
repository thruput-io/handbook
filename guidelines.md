# This document 
## Usage 
This file is shared by all Thruput developers. This document is maintained in the handbook repo. It is linked into each project via a symlic. To make updates to it you need to
follow the symlink and make updates in its real locations. Then push it to the handbook repo.
You should also make periodic pulls in the handbook repo to have an updated version of this document. At least once per day.
Please make a git pull in the handbook folder and touch this document. Then you can verify the timestamp of the file to see when you pulled it last time.
There should be a project_guidelines.md besides this file in your project ./junie folder if there is not one create it. In that file project-specific instructions
should be stored. It should also state if what kind of project this is backend or frontend. Add the symlinc to guidelines.md to .gitignore after creating it.

## Abbreviations
- This document (guidelines.md) is gl
- The project specific (project_guidelines.md) pgl
- be means Backend
- fe means Frontend

## Prompts for this document
- "Add "sample sample" to be gl" Means: make a pull in handbook repo. Update the guidelines.md with a bullet under Backend section (* sample sample). Push the handbook repo.
- "Add "sample sample" to fe gl" Means: make a pull in handbook repo. Update the guidelines.md with a bullet under Frontend section (* sample sample). Push the handbook repo.

# Coding - Design Rules and guidelines
## Generic - This section applies to both front-end and back end
- Use the `.tmp/` folder for any temporary files created by you when you are solving tasks
- Contract first. All interaction with rest endpoints should be done through contracts.
- There should always be a domain model that is used by application code. The domain serves as an abstraction layer between the application and the contracts.
- The domain model should be very strict. It should be impossible to create invalid instances of it.
- The domain model should be immutable.
- Nothing but the domain model should be allowed in any public api of components, hooks, and services.
- We never have any primitive types in the domain model.

## Backend - This section applies to back end projects
- Contracts are located in Contract project of the solution.
- In domain, we wrap all primitives by subclassing PrimitiveWrapper
- For instance, a createdAt timestamp on a domain model object 'Lead' should not be just a Instant. It should be a type (LeadCreated) that is a sublass of InstantPrimtiveWrapper. This property has a very specific meaning and should not be reused anywhere else. It should have its own type.
- Update sdk
  - dotnet restore --interactive && dotnet package search International.NET.Sdk --take 1
  - Use the version retrieved from this command to update global.json
  - After run dotnet restore --interactive again

## Frontend - This section applies to front end projects
- From the contracts we generate the code into the `src/api/generated` folder. Generated code should not be checked in.
- Zod is used to generate client and object from the contracts
- For instance, a createdAt timestamp on a domain model object 'Lead' should not be just a Temporal.Instant. It should be a branded type (LeadCreatedAtBrand) that wraps Temporal.Instant. This property has a very specific meaning and should not be reused anywhere else. It should have its own type.