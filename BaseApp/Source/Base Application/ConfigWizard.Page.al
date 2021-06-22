page 8629 "Config. Wizard"
{
    Caption = 'Welcome to RapidStart Services for Business Central';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Step 4,Step 5';
    ShowFilter = false;
    SourceTable = "Config. Setup";

    layout
    {
        area(content)
        {
            group("Step 1. Enter your company details.")
            {
                Caption = 'Step 1. Enter your company details.';
                group(Control5)
                {
                    ShowCaption = false;
                    field(Name; Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name (Required)';
                        ToolTip = 'Specifies the name of your company that you are configuring.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies an address for the company that you are configuring.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the city where the company that you are configuring is located.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("VAT Registration No."; "VAT Registration No.")
                    {
                        ApplicationArea = VAT;
                        ToolTip = 'Specifies the customer''s VAT registration number.';
                    }
                    field("Industrial Classification"; "Industrial Classification")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of industry that the company that you are configuring is.';
                    }
                }
                field(Picture; Picture)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the picture that has been set up for the company, for example, a company logo.';
                }
            }
            group("Step 2. Enter communication details.")
            {
                Caption = 'Step 2. Enter communication details.';
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the company that you are configuring.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies fax number of the company that you are configuring.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the company that you are configuring.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your company''s web site.';
                }
            }
            group("Step 3. Enter payment details.")
            {
                Caption = 'Step 3. Enter payment details.';
                field("Bank Name"; "Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank the company uses.';
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the branch number of the bank that the company that you are configuring uses.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the company that you are configuring.';
                }
                field("Payment Routing No."; "Payment Routing No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment routing number of the company that you are configuring.';
                }
                field("Giro No."; "Giro No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the giro number of the company that you are configuring.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the primary bank of the company that you are configuring.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank account number of the primary bank account of the company that you are configuring.';
                }
            }
            group("Step 4. Select package.")
            {
                Caption = 'Step 4. Select package.';
                group(Control2)
                {
                    ShowCaption = false;
                    field(PackageFileNameRtc; PackageFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select the configuration package you want to load:';
                        Editable = false;
                        ToolTip = 'Specifies the name of the configuration package that you have created.';

                        trigger OnAssistEdit()
                        var
                            FileManagement: Codeunit "File Management";
                            ConfigXMLExchange: Codeunit "Config. XML Exchange";
                        begin
                            if ConfigVisible then
                                Error(PackageIsAlreadyAppliedErr);

                            "Package File Name" :=
                              CopyStr(
                                FileManagement.OpenFileDialog(
                                  Text004, '', ConfigXMLExchange.GetFileDialogFilter), 1, MaxStrLen("Package File Name"));

                            if "Package File Name" <> '' then begin
                                Validate("Package File Name");
                                ApplyVisible := true;
                            end else
                                ApplyVisible := false;
                            PackageFileName := FileManagement.GetFileName("Package File Name");
                        end;

                        trigger OnValidate()
                        begin
                            if "Package File Name" = '' then
                                ApplyVisible := false;

                            CurrPage.Update;
                        end;
                    }
                    field("Package Code"; "Package Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code of the configuration package.';
                    }
                    field("Package Name"; "Package Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the name of the package that contains the configuration information.';
                    }
                    label("Choose Apply Package action to load the data from the configuration to Business Central tables.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Apply Package action to load the data from the configuration to Business Central tables.';
                        ToolTip = 'Specifies the action that loads the configuration data.';
                    }
                    label("Choose Configuration Worksheet if you want to edit and modify applied data.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Configuration Worksheet if you want to edit and modify applied data.';
                        ToolTip = 'Specifies the action that loads the configuration data.';
                    }
                }
            }
            group("Step 5. Select profile.")
            {
                Caption = 'Step 5. Select profile.';
                group(Control11)
                {
                    ShowCaption = false;
                    group(Control9)
                    {
                        ShowCaption = false;
                        label(ProfileText)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'If you are finished setting up your company, select the profile that you want to use as your default, and then choose the OK button to close the Wizard.';
                            ToolTip = 'Specifies the action that loads the configuration data.';
                        }
                        field("Your Profile Code"; YourProfileCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Select the profile that you want to use after the setup has completed.';
                            DrillDown = false;
                            Editable = false;
                            ToolTip = 'Specifies the profile code for your configuration solution and package.';

                            trigger OnAssistEdit()
                            var
                                AllProfileTable: Record "All Profile";
                            begin
                                if PAGE.RunModal(PAGE::"Available Roles", AllProfileTable) = ACTION::LookupOK then begin
                                    YourProfileCode := AllProfileTable."Profile ID";
                                    "Your Profile Code" := AllProfileTable."Profile ID";
                                    "Your Profile App ID" := AllProfileTable."App ID";
                                    "Your Profile Scope" := AllProfileTable.Scope;
                                end;
                            end;
                        }
                    }
                    label(BeforeSetupCloseMessage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you still need to change setup data, do not change the profile. Choose the OK button to close the wizard, and then use the configuration worksheet to continue setting up Business Central.';
                        Style = Attention;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies how to set up Dynamics 365 Business Central';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                action("Apply Package")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Package';
                    Enabled = ApplyVisible;
                    Image = Apply;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Import the configuration package and apply the package database data at the same time.';

                    trigger OnAction()
                    begin
                        if CompleteWizard then
                            ConfigVisible := true
                        else
                            Error(Text003);
                    end;
                }
                action("Configuration Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Configuration Worksheet';
                    Enabled = ConfigVisible;
                    Image = SetupLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Config. Worksheet";
                    ToolTip = 'Plan and configure how to initialize a new solution based on legacy data and the customers requirements.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';
                action(Users)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users';
                    Image = User;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page Users;
                    ToolTip = 'Open the list of users that are registered in the system.';
                }
                action("Users Personalization")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users Personalization';
                    Image = UserSetup;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "User Personalization List";
                    ToolTip = 'Open the list of personalized UIs that are registered in the system.';
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        SelectDefaultRoleCenter("Your Profile Code", "Your Profile App ID", "Your Profile Scope");
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end else begin
            "Package File Name" := '';
            "Package Name" := '';
            "Package Code" := '';
            Modify;
        end;
        YourProfileCode := "Your Profile Code";
    end;

    var
        Text003: Label 'Select a package to run the Apply Package function.';
        Text004: Label 'Select a package file.';
        YourProfileCode: Code[30];
        ApplyVisible: Boolean;
        ConfigVisible: Boolean;
        PackageIsAlreadyAppliedErr: Label 'A package has already been selected and applied.';
        PackageFileName: Text;
}

