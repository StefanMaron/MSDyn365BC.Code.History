codeunit 1878 "Guided Experience Subscribers"
{
    var
        BusinessManagerRoleCenterTourShortTitleTxt: Label 'A first look around';
        BusinessManagerRoleCenterTourTitleTxt: Label 'Take a first look around';
        BusinessManagerRoleCenterTourDescriptionTxt: Label 'The role-based home page offers quick access to key metrics and activities. We''ll also show you how to explore all the Business Central features.';
        AccountantRoleCenterTourShortTitleTxt: Label 'A first look around';
        AccountantRoleCenterTourTitleTxt: Label 'Take a first look around';
        AccountantRoleCenterTourDescriptionTxt: Label 'The role-based home page offers quick access to key metrics and activities. We''ll also show you how to explore all the Business Central features.';
        OrderProcessorRoleCenterTourShortTitleTxt: Label 'A first look around';
        OrderProcessorRoleCenterTourTitleTxt: Label 'Take a first look around';
        OrderProcessorRoleCenterTourDescriptionTxt: Label 'The role-based home page offers quick access to key metrics and activities. We''ll also show you how to explore all the Business Central features.';
        EditCustomerListInExcelShortTitleTxt: Label 'Edit and analyze in Excel';
        EditCustomerListInExcelTitleTxt: Label 'Edit and analyze in Excel';
        EditCustomerListInExcelDescriptionTxt: Label 'Open business data in Microsoft Excel to quickly analyze data with familiar tools. Let''s show you how with the Customer List.';
        CustomerListSpotlightTourStep1TitleTxt: Label 'Get the list of customers into Excel';
        CustomerListSpotlightTourStep1TextTxt: Label 'This is the list of your customers. You can view, edit, and analyze lists like this in Microsoft Excel.';
        CustomerListSpotlightTourStep2TitleTxt: Label 'Open in Excel';
        CustomerListSpotlightTourStep2TextTxt: Label 'When you choose to open the list in Excel you can use it for analysis and calculations that you do not need to save back into Business Central.';
        ItemCardShareToTeamsShortTitleTxt: Label 'Share to Teams';
        ItemCardShareToTeamsTitleTxt: Label 'Share business data to Teams';
        ItemCardShareToTeamsDescriptionTxt: Label 'Quickly share and collaborate on business tasks in Microsoft Teams. For example, sharing a link to an item card without the need to switch apps.';
        ItemCardSpotlightTourStep1TitleTxt: Label 'Share item details to Teams';
        ItemCardSpotlightTourStep1TextTxt: Label 'This is an item card, where you manage information about a product or service. You can share information in cards with your colleagues through Microsoft Teams.';
        ItemCardSpotlightTourStep2TitleTxt: Label 'Share to Teams';
        ItemCardSpotlightTourStep2TextTxt: Label 'Need to colaborate with a co-worker about the details of an item? Simply share this item by hitting the share icon.';
        YourSalesWithinOutlookShortTitleTxt: Label 'Manage sales in Outlook';
        YourSalesWithinOutlookTitleTxt: Label 'Manage sales while in Outlook';
        YourSalesWithinOutlookDescriptionTxt: Label 'Business Central is available in Outlook. You can manage quotes and invoices right next to a mail you received, without leaving Outlook.';
        YourSalesWithinOutlookVideoLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170901', Locked = true;
        ChartOfAccountSetupShortTitleTxt: Label 'Chart of Accounts';
        ChartOfAccountSetupTitleTxt: Label 'Review the chart of accounts';
        ChartOfAccountSetupDescriptionTxt: Label 'Organize your business down to the finest detail with the chart of accounts to track the financials across your business.';
        BankAccountsSetupShortTitleTxt: Label 'Bank Accounts';
        BankAccountsSetupTitleTxt: Label 'Set up your bank accounts';
        BankAccountsSetupDescriptionTxt: Label 'Configure the bank accounts that you use to pay vendors, and which receive payments from customers.';
        SalesQuotesTitleTxt: Label 'Make offers to your customers';
        SalesQuotesShortTitleTxt: Label 'Sales Quotes';
        SalesQuotesDescriptionTxt: Label 'Create quotes to send estimates to your customers or prospects with an offer for items or services.';
        SalesOrdersTitleTxt: Label 'Manage orders, fulfillment, and invoicing';
        SalesOrdersShortTitleTxt: Label 'Sales Orders';
        SalesOrdersDescriptionTxt: Label 'Sales orders track what is ordered, what is shipped, and what is invoiced, all in a way that is connected to your inventory.';
        SalesInvoicesTitleTxt: Label 'Send invoices and get paid';
        SalesInvoicesShortTitleTxt: Label 'Sales Invoices';
        SalesInvoicesDescriptionTxt: Label 'Create invoices directly when you ship and invoice in one go, otherwise use sales orders.';
        SalesInvoiceHistoryTitleTxt: Label 'Overview your posted sales invoices';
        SalesInvoiceHistoryShortTitleTxt: Label 'Sales Invoice History';
        SalesInvoiceHistoryDescriptionTxt: Label 'All invoices end up in the Posted Sales Invoices list where you can track status and make corrections if needed.';
        ReturnOrdersTitleTxt: Label 'Process sales returns';
        ReturnOrdersShortTitleTxt: Label 'Sales Return Orders';
        ReturnOrdersDescriptionTxt: Label 'Manage the return of products from customers to track warehouse receipt, refund, if applicable, and the reason for the return.';

    procedure GetYourSalesWithinOutlookVideoLinkTxt(): Text
    begin
        exit(YourSalesWithinOutlookDescriptionTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterGuidedExperienceItem', '', false, false)]
    local procedure OnRegisterGuidedExperienceItem()
    var
        GuidedExperience: Codeunit "Guided Experience";
        SpotlightTourType: Enum "Spotlight Tour Type";
        VideoCategory: Enum "Video Category";
        CustomerListSpotlightDictionary: Dictionary of [Enum "Spotlight Tour Text", Text];
        ItemCardSpotlightDictionary: Dictionary of [Enum "Spotlight Tour Text", Text];
    begin
        GuidedExperience.InsertTour(BusinessManagerRoleCenterTourTitleTxt, BusinessManagerRoleCenterTourShortTitleTxt,
            BusinessManagerRoleCenterTourDescriptionTxt, 2, Page::"Business Manager Role Center");

        GuidedExperience.InsertTour(AccountantRoleCenterTourTitleTxt, AccountantRoleCenterTourShortTitleTxt,
            AccountantRoleCenterTourDescriptionTxt, 2, Page::"Accountant Role Center");

        GuidedExperience.InsertTour(OrderProcessorRoleCenterTourTitleTxt, OrderProcessorRoleCenterTourShortTitleTxt,
            OrderProcessorRoleCenterTourDescriptionTxt, 2, Page::"Order Processor Role Center");

        GetCustomerListSpotlightDictionary(CustomerListSpotlightDictionary);
        GuidedExperience.InsertSpotlightTour(EditCustomerListInExcelTitleTxt, EditCustomerListInExcelShortTitleTxt,
            EditCustomerListInExcelDescriptionTxt, 2, Page::"Customer List", SpotlightTourType::"Open in Excel", CustomerListSpotlightDictionary);

        GetItemCardSpotlightDictionary(ItemCardSpotlightDictionary);
        GuidedExperience.InsertSpotlightTour(ItemCardShareToTeamsTitleTxt, ItemCardShareToTeamsShortTitleTxt,
            ItemCardShareToTeamsDescriptionTxt, 2, Page::"Item Card", SpotlightTourType::"Share to Teams", ItemCardSpotlightDictionary);

        GuidedExperience.InsertVideo(YourSalesWithinOutlookTitleTxt, YourSalesWithinOutlookShortTitleTxt,
            YourSalesWithinOutlookDescriptionTxt, 2, YourSalesWithinOutlookVideoLinkTxt, VideoCategory::GettingStarted);

        GuidedExperience.InsertApplicationFeature(ChartOfAccountSetupTitleTxt, ChartOfAccountSetupShortTitleTxt, ChartOfAccountSetupDescriptionTxt, 10, ObjectType::Page,
            Page::"Chart of Accounts");
        GuidedExperience.InsertApplicationFeature(BankAccountsSetupTitleTxt, BankAccountsSetupShortTitleTxt, BankAccountsSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"Bank Account List");
        GuidedExperience.InsertApplicationFeature(SalesQuotesTitleTxt, SalesQuotesShortTitleTxt, SalesQuotesDescriptionTxt, 15, ObjectType::Page,
            Page::"Sales Quotes");
        GuidedExperience.InsertApplicationFeature(SalesOrdersTitleTxt, SalesOrdersShortTitleTxt, SalesOrdersDescriptionTxt, 15, ObjectType::Page,
            Page::"Sales Order List");
        GuidedExperience.InsertApplicationFeature(SalesInvoicesTitleTxt, SalesInvoicesShortTitleTxt, SalesInvoicesDescriptionTxt, 15, ObjectType::Page,
            Page::"Sales Invoice List");
        GuidedExperience.InsertApplicationFeature(SalesInvoiceHistoryTitleTxt, SalesInvoiceHistoryShortTitleTxt, SalesInvoiceHistoryDescriptionTxt, 15, ObjectType::Page,
            Page::"Posted Sales Invoices");
        GuidedExperience.InsertApplicationFeature(ReturnOrdersTitleTxt, ReturnOrdersShortTitleTxt, ReturnOrdersDescriptionTxt, 15, ObjectType::Page,
           Page::"Sales Return Order List");
    end;

    local procedure GetCustomerListSpotlightDictionary(var CustomerListSpotlightDictionary: Dictionary of [Enum "Spotlight Tour Text", Text])
    var
        SpotlightTourText: Enum "Spotlight Tour Text";
    begin
        CustomerListSpotlightDictionary.Add(SpotlightTourText::Step1Title, CustomerListSpotlightTourStep1TitleTxt);
        CustomerListSpotlightDictionary.Add(SpotlightTourText::Step1Text, CustomerListSpotlightTourStep1TextTxt);

        CustomerListSpotlightDictionary.Add(SpotlightTourText::Step2Title, CustomerListSpotlightTourStep2TitleTxt);
        CustomerListSpotlightDictionary.Add(SpotlightTourText::Step2Text, CustomerListSpotlightTourStep2TextTxt);
    end;

    local procedure GetItemCardSpotlightDictionary(var ItemCardSpotlightDictionary: Dictionary of [Enum "Spotlight Tour Text", Text])
    var
        SpotlightTourText: Enum "Spotlight Tour Text";
    begin
        ItemCardSpotlightDictionary.Add(SpotlightTourText::Step1Title, ItemCardSpotlightTourStep1TitleTxt);
        ItemCardSpotlightDictionary.Add(SpotlightTourText::Step1Text, ItemCardSpotlightTourStep1TextTxt);

        ItemCardSpotlightDictionary.Add(SpotlightTourText::Step2Title, ItemCardSpotlightTourStep2TitleTxt);
        ItemCardSpotlightDictionary.Add(SpotlightTourText::Step2Text, ItemCardSpotlightTourStep2TextTxt);
    end;
}