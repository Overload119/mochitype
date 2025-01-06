import type { TMochitypesUsersUserShowDetailsSchema } from "./__generated__/mochitypes/users/show";

// Get CSRF token from meta tag
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

async function fetchShowData() {
  try {
    const response = await fetch("/show", {
      method: "GET",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || "",
      },
      credentials: "same-origin",
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error("Error fetching show data:", error);
    throw error;
  }
}

document.addEventListener("DOMContentLoaded", async () => {
  try {
    const data = await fetchShowData();
    console.log("Show data loaded:", data);
  } catch (error) {
    console.error("Failed to load show data:", error);
  }
});
