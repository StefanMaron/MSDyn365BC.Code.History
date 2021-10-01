Page 1 "Company Information"
{
    AdditionalSearchTerms = 'change experience,suite,user interface,company badge';
    ApplicationArea = Basic, Suite;
    Caption = 'Company Information';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Application Settings,System Settings,Currencies,Codes,Regional Settings';
    SourceTable = "Company Information";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the company''s name and corporate form. For example, Inc. or Ltd.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the company''s address.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the company''s city.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state, province or county of the company''s address.';
                    Visible = CountyVisible;
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the postal code.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Contact Person"; "Contact Person")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact Name';
                    ToolTip = 'Specifies the name of the contact person in your company.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s telephone number.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the company''s VAT registration number.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditCompanyInfoVATReg();
                    end;
                }
                field(GLN; GLN)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies your company in connection with electronic document exchange.';
                }
                field("Use GLN in Electronic Document"; "Use GLN in Electronic Document")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies whether the GLN is used in electronic documents as a party identification number.';
                }
                field("EORI Number"; "EORI Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Economic Operators Registration and Identification number that is used when you exchange information with the customs authorities due to trade into or out of the European Union.';
                    Visible = false;
                }
                field("Industrial Classification"; "Industrial Classification")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the company''s industrial classification code.';
                }
                field(Picture; Picture)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the picture that has been set up for the company, such as a company logo.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the company''s telephone number.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the company''s fax number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s email address.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your company''s web site.';
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies your company''s intercompany partner code.';
                }
                field("IC Inbox Type"; "IC Inbox Type")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies what type of intercompany inbox you have, either File Location or Database.';
                }
                field("IC Inbox Details"; "IC Inbox Details")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies details about the location of your intercompany inbox, which can transfer intercompany transactions into your company.';
                }
                field("Auto. Send Transactions"; "Auto. Send Transactions")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies that as soon as transactions arrive in the intercompany outbox, they will be sent to the intercompany partner.';
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Allow Blank Payment Info."; "Allow Blank Payment Info.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you are allowed to create a sales invoice without filling the setup fields on this FastTab.';
                }
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the bank the company uses.';
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = IBANMissing;
                    ToolTip = 'Specifies the bank''s branch number.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions
                    end;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = IBANMissing;
                    ToolTip = 'Specifies the company''s bank account number.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions
                    end;
                }
                field("Payment Routing No."; "Payment Routing No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s payment routing number.';
                }
                field("Giro No."; "Giro No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s giro number.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of your primary bank.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions
                    end;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = BankBranchNoOrAccountNoMissing;
                    ToolTip = 'Specifies the international bank account number of your primary bank account.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions
                    end;
                }
                field(BankAccountPostingGroup; BankAcctPostingGroup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Posting Group';
                    Lookup = true;
                    TableRelation = "Bank Account Posting Group".Code;
                    ToolTip = 'Specifies a code for the bank account posting group for the company''s bank account.';

                    trigger OnValidate()
                    var
                        BankAccount: Record "Bank Account";
                    begin
                        CompanyInformationMgt.UpdateCompanyBankAccount(Rec, BankAcctPostingGroup, BankAccount);
                    end;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the location to which items for the company should be shipped.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the location to which items for the company should be shipped.';
                }
                field("Ship-to Address 2"; "Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the company''s ship-to address.';
                }
                field("Ship-to County"; "Ship-to County")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to County';
                    ToolTip = 'Specifies the county of the company''s shipping address.';
                    Visible = CountyVisible;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code that corresponds to the company''s ship-to address.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the default responsibility center.';
                }
                field("Check-Avail. Period Calc."; "Check-Avail. Period Calc.")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies a date formula that defines the length of the period after the planned shipment date on demand lines in which the system checks availability for the demand line in question.';
                }
                field("Check-Avail. Time Bucket"; "Check-Avail. Time Bucket")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how frequently the system checks supply-demand events to discover if the item on the demand line is available on its shipment date.';
                }
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the code for the base calendar that you want to assign to your company.';
                }
                field("Customized Calendar"; format(CalendarMgmt.CustomizedChangesExist(Rec)))
                {
                    ApplicationArea = Suite;
                    Caption = 'Customized Calendar';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies whether or not your company has set up a customized calendar.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord;
                        TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
                }
                field("Cal. Convergence Time Frame"; "Cal. Convergence Time Frame")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how dates based on calendar and calendar-related documents are calculated.';
                }
            }
            group("System Indicator")
            {
                Caption = 'Company Badge';
                field("Company Badge"; "System Indicator")
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Badge';
                    ToolTip = 'Specifies how you want to use the Company Badge when you are working with different companies of Business Central.';

                    trigger OnValidate()
                    begin
                        SystemIndicatorOnAfterValidate;
                    end;
                }
                field("System Indicator Style"; "System Indicator Style")
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Badge Style';
                    ToolTip = 'Specifies if you want to apply a certain style to the Company Badge. Having different styles on badges can make it easier to recognize the company that you are currently working with.';
                    OptionCaption = 'Dark Blue,Light Blue,Dark Green,Light Green,Dark Yellow,Light Yellow,Red,Orange,Deep Purple,Bright Purple';

                    trigger OnValidate()
                    begin
                        SystemIndicatorOnAfterValidate;
                    end;
                }
                field("System Indicator Text"; SystemIndicatorText)
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Badge Text';
                    Editable = SystemIndicatorTextEditable;
                    ToolTip = 'Specifies text that you want to use in the Company Badge. Only the first 4 characters will be shown in the badge.';

                    trigger OnValidate()
                    begin
                        "Custom System Indicator Text" := SystemIndicatorText;
                        SystemIndicatorOnAfterValidate;
                    end;
                }
            }
            group("User Experience")
            {
                Caption = 'User Experience';
                field(Experience; Experience)
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    Caption = 'Experience';
                    Editable = false;
                    ToolTip = 'Specifies which UI elements are displayed and which features are available. The setting applies to all users. Essential: Shows all actions and fields for all common business functionality. Premium: Shows all actions and fields for all business functionality, including Manufacturing and Service Management.';

                    trigger OnAssistEdit()
                    var
                        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                    begin
                        ApplicationAreaMgmtFacade.LookupExperienceTier(Experience);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Responsibility Centers")
            {
                ApplicationArea = Advanced;
                Caption = 'Responsibility Centers';
                Image = Position;
                RunObject = Page "Responsibility Center List";
                ToolTip = 'Set up responsibility centers to administer business operations that cover multiple locations, such as a sales offices or a purchasing departments.';
            }
            action("Report Layouts")
            {
                ApplicationArea = Advanced;
                Caption = 'Report Layouts';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Page "Report Layout Selection";
                ToolTip = 'Specify the layout to use on reports when viewing, printing, and saving them. The layout defines things like text font, field placement, or background.';
            }
            group("Application Settings")
            {
                Caption = 'Application Settings';
                group(Setup)
                {
                    Caption = 'Setup';
                    Image = Setup;
                    action("General Ledger Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'General Ledger Setup';
                        Image = JournalSetup;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedIsBig = true;
                        RunObject = Page "General Ledger Setup";
                        ToolTip = 'Define your general accounting policies, such as the allowed posting period and how payments are processed. Set up your default dimensions for financial analysis.';
                    }
                    action("Sales & Receivables Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Sales & Receivables Setup';
                        Image = ReceivablesPayablesSetup;
                        RunObject = Page "Sales & Receivables Setup";
                        ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
                    }
                    action("Purchases & Payables Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Purchases & Payables Setup';
                        Image = Purchase;
                        RunObject = Page "Purchases & Payables Setup";
                        ToolTip = 'Define your general policies for purchase invoicing and returns, such as whether to require vendor invoice numbers and how to post purchase discounts. Set up your number series for creating vendors and different purchase documents.';
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Inventory Setup';
                        Image = InventorySetup;
                        RunObject = Page "Inventory Setup";
                        ToolTip = 'Define your general inventory policies, such as whether to allow negative inventory and how to post and adjust item costs. Set up your number series for creating new inventory items or services.';
                    }
                    action("Fixed Assets Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Fixed Assets Setup';
                        Image = FixedAssets;
                        RunObject = Page "Fixed Asset Setup";
                        ToolTip = 'Define your accounting policies for fixed assets, such as the allowed posting period and whether to allow posting to main assets. Set up your number series for creating new fixed assets.';
                    }
                    action("Human Resources Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Human Resources Setup';
                        Image = HRSetup;
                        RunObject = Page "Human Resources Setup";
                        ToolTip = 'Set up number series for creating new employee cards and define if employment time is measured by days or hours.';
                    }
                    action("Jobs Setup")
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Jobs Setup';
                        Image = Job;
                        RunObject = Page "Jobs Setup";
                        ToolTip = 'Define your accounting policies for jobs, such as which WIP method to use and whether to update job item costs automatically.';
                    }
                }
                action("No. Series")
                {
                    ApplicationArea = Advanced;
                    Caption = 'No. Series';
                    Image = NumberSetup;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "No. Series";
                    ToolTip = 'Set up the number series from which a new number is automatically assigned to new cards and documents, such as item cards and sales invoices.';
                }
            }
            group("System Settings")
            {
                Caption = 'System Settings';
                action(Users)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Users';
                    Image = Users;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page Users;
                    ToolTip = 'Set up the employees who will work in this company.';
                }
                action("Permission Sets")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Permission Sets';
                    Image = Permission;
                    RunObject = Page "Permission Sets";
                    ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
                }
                action("SMTP Mail Setup")
                {
                    ApplicationArea = Advanced;
                    Caption = 'SMTP Mail Setup';
                    Image = MailSetup;
                    RunObject = Page "SMTP Mail Setup";
                    ToolTip = 'Set up the integration and security of the mail server at your site that handles email.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced with the ''Email Account Setup'' action';
                    ObsoleteTag = '17.0';
                    Visible = not IsEmailFeatureEnabled;
                }
                action("Email Account Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email Account Setup';
                    Image = MailSetup;
                    RunObject = page "Email Accounts";
                    ToolTip = 'Set up email accounts used in the product.';
                    Visible = IsEmailFeatureEnabled;
                }
            }
            group(Currencies)
            {
                Caption = 'Currencies';
                action(Action27)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Currencies';
                    Image = Currencies;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page Currencies;
                    ToolTip = 'Set up the different currencies that you trade in by defining which general ledger accounts the involved transactions are posted to and how the foreign currency amounts are rounded.';
                }
            }
            group("Regional Settings")
            {
                Caption = 'Regional Settings';
                action("Countries/Regions")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Countries/Regions';
                    Image = CountryRegion;
                    RunObject = Page "Countries/Regions";
                    ToolTip = 'Set up the country/regions where your different business partners are located, so that you can assign Country/Region codes to business partners where special local procedures are required.';
                }
                action("Post Codes")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Post Codes';
                    Image = MailSetup;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    RunObject = Page "Post Codes";
                    ToolTip = 'Set up the post codes of cities where your business partners are located.';
                }
                action("Online Map Setup")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Online Map Setup';
                    Image = MapSetup;
                    RunObject = Page "Online Map Setup";
                    ToolTip = 'Define which map provider to use and how routes and distances are displayed when you choose the Online Map field on business documents.';
                }
                action(Languages)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Languages';
                    Image = Language;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page Languages;
                    ToolTip = 'Set up the languages that are spoken by your different business partners, so that you can print item names or descriptions in the relevant language.';
                }
            }
            group(Codes)
            {
                Caption = 'Codes';
                action("Source Codes")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Source Codes';
                    Image = CodesList;
                    RunObject = Page "Source Codes";
                    ToolTip = 'Set up codes for your different types of business transactions, so that you can track the source of the transactions in an audit.';
                }
                action("Reason Codes")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Reason Codes';
                    Image = CodesList;
                    RunObject = Page "Reason Codes";
                    ToolTip = 'View or set up codes that specify reasons why entries were created, such as Return, to specify why a purchase credit memo was posted.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSystemIndicator;
    end;

    trigger OnClosePage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(Experience) then
            RestartSession;

        if SystemIndicatorChanged then begin
            Message(CompanyBadgeRefreshPageTxt);
            RestartSession();
        end;
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        SetShowMandatoryConditions;
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EmailFeature: Codeunit "Email Feature";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        IsEmailFeatureEnabled := EmailFeature.IsEnabled();
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        CountyVisible := FormatAddress.UseCounty("Country/Region Code");

        ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(Experience);
        MonitorSensitiveField.ShowPromoteMonitorSensitiveFieldNotification();

        BankAcctPostingGroup := CompanyInformationMgt.GetCompanyBankAccountPostingGroup();
    end;

    var
        CalendarMgmt: Codeunit "Calendar Management";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        FormatAddress: Codeunit "Format Address";
        EnvironmentInfo: Codeunit "Environment Information";
        Experience: Text;
        SystemIndicatorText: Code[4];
        [InDataSet]
        SystemIndicatorTextEditable: Boolean;
        IBANMissing: Boolean;
        BankBranchNoOrAccountNoMissing: Boolean;
        BankAcctPostingGroup: Code[20];
        CountyVisible: Boolean;
        SystemIndicatorChanged: Boolean;
        CompanyBadgeRefreshPageTxt: Label 'The Company Badge settings have changed. Refresh the browser (Ctrl+F5) to update the badge.';
        IsEmailFeatureEnabled: Boolean;

    local procedure UpdateSystemIndicator()
    var
        CustomSystemIndicatorText: Text[250];
        IndicatorStyle: Option;
    begin
        GetSystemIndicator(CustomSystemIndicatorText, IndicatorStyle); // IndicatorStyle is not used
        SystemIndicatorText := CopyStr(CustomSystemIndicatorText, 1, 4);
        SystemIndicatorTextEditable := CurrPage.Editable and ("System Indicator" = "System Indicator"::"Custom");
    end;

    local procedure SystemIndicatorOnAfterValidate()
    begin
        SystemIndicatorChanged := true;
        UpdateSystemIndicator
    end;

    local procedure SetShowMandatoryConditions()
    begin
        BankBranchNoOrAccountNoMissing := ("Bank Branch No." = '') or ("Bank Account No." = '');
        IBANMissing := IBAN = ''
    end;

    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;
}

