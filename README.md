# Item Purchase Tool

**Item Purchase Tool** is a Salesforce application for managing items and purchases.

## Key Features
- Create and manage items with required fields: Name, Price, Family, and Type.  
- Add items to a cart and complete purchases.  
- Automatically calculate the purchase total and create purchase line items.  
- Role-based access: managers can create and edit items.  
- Integration with the Unsplash API to fetch images for items by name.  
- Filter and search items by Family, Type, and keywords.  
- Track changes in purchase lines using triggers.

All components are implemented using **Lightning Web Components (LWC)** and **Apex classes**.  

Unit tests cover main scenarios: item creation, user role validation, checkout process, and error handling.
