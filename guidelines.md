# This document 
## Usage 
This file is shared by all Thruput developers. This document is maintained in the handbook repo. It is linked into each project via a symlic. To make updates to it you need to
follow the symlink and make updates in its real locations. Then push it to the handbook repo.
You should also make periodic pulls in the handbook repo to have an updated version of this document. At least once per day.
Please make a git pull in the handbook folder and touch this document. Then you can verify the timestamp of the file to see when you pulled it last time.
There should be a project_guidelines.md besides this file in your project ./junie folder if there is not one create it. In that file project-specific instructions
should be stored. It should also state if what kind of project this is backend or frontend. Add the symlinc to guidelines.md to .gitignore after creating it.

- Before adding new guidelines make sure to correct spelling

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
- Use the `.tmp/` folder for any temporary files created by you when you are solving tasks. Never create temporary files (like `.output.txt`) in the root folder.
- Contract first. All interaction with rest endpoints should be done through contracts.
- There should always be a domain model that is used by application code. The domain serves as an abstraction layer between the application and the contracts.
- The domain model should be very strict. It should be impossible to create invalid instances of it.
- The domain model should be immutable.
- Nothing but the domain model should be allowed in any public api of components, hooks, and services.
- We never have any primitive types in the domain model.
- We strive to do validation and defaulting at the perimiters of our code base. Our domain model should make invalid states unrepresentable. This makes out code much more simple with much fewer branches and extending it is easy. In React this means we resolve optional parameters as high as possible in our component hiearchy

## Backend - This section applies to back end projects
- After each code change I should build solution fix all warnings and run all tests
- Contracts are located in Contract project of the solution.
- In domain, we wrap all primitives by subclassing PrimitiveWrapper
- Subtypes of PrimitiveWrapper must have private ctor
- For instance, a createdAt timestamp on a domain model object 'Lead' should not be just a Instant. It should be a type (LeadCreated) that is a sublass of InstantPrimtiveWrapper. This property has a very specific meaning and should not be reused anywhere else. It should have its own type.

## Test - This section applies to all projects when writing tests
- Do not use comments
- Do not hesitate to remove comments when they are not needed
- Always write a test to verify bugs before fixing them

### Integration tests - this section applies to integration tests
- When writing integration tests, prefer using raw json data instead of domain models.
- Always use the application entry points, api's or streams, to insert test data.

### Common Tasks
- **Update sdk**:
    1. dotnet restore --interactive && dotnet package search International.NET.Sdk --take 1
    2. Use the version retrieved from this command to update global.json
    3. fter run dotnet restore --interactive again

## Frontend - This section applies to front end projects
- There should never be a try catch in my fe code excpet for very specific things such as setting up error boundries 
- From the contracts we generate the code into the `src/api/generated` folder. Generated code should not be checked in.
- Zod is used to generate client and object from the contracts
- For instance, a createdAt timestamp on a domain model object 'Lead' should not be just a Temporal.Instant. It should be a branded type (LeadCreatedAtBrand) that wraps Temporal.Instant. This property has a very specific meaning and should not be reused anywhere else. It should have its own type.
- In E2E tests make a setup that captures the console logs and examine them first in case of test failure

### Figma MCP Integration Rules
These rules define how to translate Figma inputs into code for this project and must be followed for every Figma-driven change.
Use your special tools like mcp_FigmaDesktop_get_screenshot and mcp_FigmaDesktop_get_design_context. Do not invent your own tools for speaking cmp server.


#### Required flow (do not skip)
1. Run get_design_context first to fetch the structured representation for the exact node(s).
2. If the response is too large or truncated, run get_metadata to get the high‑level node map and then re‑fetch only the required node(s) with get_design_context.
3. Run get_screenshot for a visual reference of the node variant being implemented.
4. Only after you have both get_design_context and get_screenshot, download any assets needed and start implementation.
5. Translate the output (usually React + Tailwind) into this project's conventions, styles and framework.  Reuse the project's color tokens, components, and typography wherever possible.
6. Validate against Figma for 1:1 look and behavior before marking complete.

#### Implementation rules
- Treat the Figma MCP output (React + Tailwind) as a representation of design and behavior, not as final code style.
- Replace Tailwind utility classes with the project's preferred utilities/design‑system tokens when applicable.
- Reuse existing components (e.g., buttons, inputs, typography, icon wrappers) instead of duplicating functionality.
- Use the project's color system, typography scale, and spacing tokens consistently.
- Respect existing routing, state management, and data‑fetch patterns already adopted in the repo.
- Strive for 1:1 visual parity with the Figma design. When conflicts arise, prefer design‑system tokens and adjust spacing or sizes minimally to match visuals.
- Validate the final UI against the Figma screenshot for both look and behavior.