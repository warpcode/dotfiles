# Smart Shopping List Skill Plan

## Objective
Create an AI skill that transforms recipe ingredients (from a list, a scraped link, etc.) into a real-world, store-specific shopping list. The skill will estimate necessary weights, search for actual products from UK supermarkets (defaulting to Waitrose), select appropriate package sizes, and format the output as a Categorised List while clearly flagging any missing items.

## Key Files & Context
- **Source:** `assets/configs/ai/skills/smart-shopping-list/SKILL.md`
- **Symlink:** `generic/.gemini/skills/smart-shopping-list`
- **Testing Workspace:** `conductor/tracks/smart-shopping-list/` (or similar workspace for `evals.json` and test runs)

## Implementation Steps

1. **Scaffold the Skill Directory:**
   - Create `assets/configs/ai/skills/smart-shopping-list/`.
   - Create `generic/.gemini/skills/smart-shopping-list/` as a symlink pointing to the assets directory.

2. **Draft `SKILL.md`:**
   - **Metadata:** Set triggers (e.g., "shopping list", "buy ingredients", "meal prep list").
   - **Phase 1: Clarification:** Ask for the recipe/list if not provided, and confirm the target supermarket (default: Waitrose).
   - **Phase 2: Extraction & Estimation:** Instructions to parse ingredients, scrape URLs if given, and estimate raw weights (e.g., 5 potatoes $\approx$ 1kg, 1 cup of rice $\approx$ 200g).
   - **Phase 3: Execution (Search):** Direct the model to use `google_web_search` with site operators (e.g., `site:waitrose.com/ecom/products "maris piper potatoes"`) to find available products. Instruct it to prefer package sizes that meet or slightly exceed the estimated requirement to minimize waste.
   - **Phase 4: Formatting:** Enforce the "Categorised List" format (grouped by aisle: Produce, Dairy, Meat, Pantry, etc.) and require an explicit "Missing/Unfound Items" section.

3. **Set Up Evals:**
   - Create `evals.json` in the testing workspace.
   - Define test cases using the user-provided ingredient list (Milk, Cheddar cheese, Butter, Eggs, Potatoes, etc.).
   - Create separate eval cases instructing the skill to target different supermarkets (Waitrose, Aldi, Morrisons, Tesco, Lidl, M&S, Asda) to ensure the search strategies adapt correctly.

4. **Iterative Testing:**
   - Run the baseline test cases with the drafted skill.
   - Review the generated shopping lists to verify correct product matching, realistic weight estimates, and adherence to the Categorised List format.
   - Adjust `SKILL.md` search instructions if the model struggles to find products on specific sites (e.g., Lidl or Aldi might require different search terms compared to Waitrose).

## Verification & Testing
- The symlink resolves correctly and the skill is loaded by the CLI.
- The generated shopping list correctly categorizes items.
- Real-world products (with prices/weights) are accurately pulled from the target supermarket's website.
- Unmatched items are safely caught and listed rather than hallucinated.