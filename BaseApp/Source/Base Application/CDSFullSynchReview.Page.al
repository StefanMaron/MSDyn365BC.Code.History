page 7208 "CDS Full Synch. Review"
{
    Caption = 'Common Data Service Full Synchronization Review', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Full Synch. Review Line";
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                    Editable = false;
                }
                field("BC Page Id"; BCPageName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Business Central';
                    Tooltip = 'Open the selected page';
                    Width = 10;
                    trigger OnDrillDown()
                    begin
                        Page.Run(BCPageId);
                        CurrPage.Update();
                    end;
                }
                field("CDS Page Id"; CDSPageName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Common Data Service', Locked = true;
                    ToolTip = 'Open the selected page and present the existing Common Data Service records.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                    Width = 10;
                    trigger OnDrillDown()
                    begin

                        case CDSPageId of
                            Page::"CRM TransactionCurrency List":
                                OpenCRMTransactionCurrenciesListPage();
                            Page::"CDS Couple Salespersons":
                                OpenCRMSystemUserListPage();
                            Page::"CRM Contact List":
                                OpenCRMContactListPage();
                            else
                                OpenCRMAccountListPage();
                        end;

                    end;
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the direction in which data will synchronize.';
                }
                field("Initial Synchronization Recommendation"; InitialSynchRecommendation)
                {
                    Caption = 'Recommendation';
                    ApplicationArea = Suite;
                    StyleExpr = InitialSynchRecommendationStyle;
                    ToolTip = 'Specifies the recommended action for the initial synchronization.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Refresh)
            {

                Caption = 'Refresh recommendation';

                action(RefreshRecommendations)
                {
                    ApplicationArea = Suite;
                    Caption = 'Refresh recommendation';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Refresh the initial synchronization recommendations.';

                    trigger OnAction()
                    begin
                        Rec.DeleteAll();
                        Rec.Generate();
                        Commit();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActionStartEnabled := (not IsThereActiveSessionInProgress()) and IsThereBlankStatusLine();
        if "Initial Synch Recommendation" = "Initial Synch Recommendation"::"Couple Records" then
            InitialSynchRecommendation := 'No Synchronization'
        else
            InitialSynchRecommendation := Format("Initial Synch Recommendation");

        InitialSynchRecommendationStyle := GetInitialSynchRecommendationStyleExpression(Format("Initial Synch Recommendation"));
        GetCDSPageId();
        GetBCPageId();
        GetCDSPageName();
        GetBCPageName();
    end;

    trigger OnOpenPage()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SetConnectionSetup(NewCDSConnectionSetup: Record "CDS Connection Setup"; NewUserPassword: Text)
    begin
        CDSConnectionSetup := NewCDSConnectionSetup;
        UserPassword := NewUserPassword;
    end;

    local procedure GetCDSPageId()
    begin
        case Name of
            'CONTACT':
                CDSPageId := 5342;
            'CURRENCY':
                CDSPageId := 5345;
            'CUSTOMER':
                CDSPageId := 5341;
            'SALESPEOPLE':
                CDSPageId := 7209;
            'VENDOR':
                CDSPageId := 5341;
        end;
    end;

    local procedure GetBCPageId()
    begin
        case Name of
            'CONTACT':
                BCPageId := 5052;
            'CURRENCY':
                BCPageId := 5;
            'CUSTOMER':
                BCPageId := 22;
            'SALESPEOPLE':
                BCPageId := 14;
            'VENDOR':
                BCPageId := 27;
        end;
    end;

    local procedure GetCDSPageName()
    begin
        case Name of
            'CONTACT':
                CDSPageName := 'Contacts';
            'CURRENCY':
                CDSPageName := 'Transaction Currencies';
            'CUSTOMER':
                CDSPageName := 'Accounts';
            'SALESPEOPLE':
                CDSPageName := 'Users';
            'VENDOR':
                CDSPageName := 'Accounts';
        end;
    end;

    local procedure GetBCPageName()
    begin
        case Name of
            'CONTACT':
                BCPageName := 'Contacts';
            'CURRENCY':
                BCPageName := 'Currencies';
            'CUSTOMER':
                BCPageName := 'Customers';
            'SALESPEOPLE':
                BCPageName := 'Salespeople/Purchasers';
            'VENDOR':
                BCPageName := 'Vendors';
        end;
    end;

    local procedure OpenCRMContactListPage()
    var
        CRMContact: Record "CRM Contact";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMContactList: Page "CRM Contact List";
    begin
        CRMContact.Reset();
        CRMContact.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Contact"));
        if not CRMContact.FindSet() then;
        CRMContactList.SetRecord(CRMContact);
        CRMContactList.SetTableView(CRMContact);
        CRMContactList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMTransactionCurrenciesListPage()
    var
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMTransactionCurrencyList: Page "CRM TransactionCurrency List";
    begin
        CRMTransactionCurrency.Reset();
        CRMTransactionCurrency.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        if not CRMTransactionCurrency.FindSet() then;
        CRMTransactionCurrencyList.SetRecord(CRMTransactionCurrency);
        CRMTransactionCurrencyList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMAccountListPage()
    var
        CRMAccount: Record "CRM Account";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CRMAccountList: Page "CRM Account List";
    begin
        CRMAccount.Reset();
        CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
        if BCPageId = PAGE::"Customer List" then
            CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer)
        else
            CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
        if not CRMAccount.FindSet() then;
        CRMAccountList.SetTableView(CRMAccount);
        CRMAccountList.SetRecord(CRMAccount);
        CRMAccountList.Run();
        CurrPage.Update();
    end;

    local procedure OpenCRMSystemUserListPage()
    var
        CRMSystemUser: Record "CRM Systemuser";
        CRMSystemuserList: Page "CRM Systemuser List";
    begin
        if CRMSystemUser.FindSet() then;
        CRMSystemuserList.SetRecord(CRMSystemUser);
        CRMSystemuserList.Run();
        CurrPage.Update();
    end;

    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        UserPassword: Text;
        ActionStartEnabled: Boolean;
        BCPageId: Integer;
        CDSPageId: Integer;
        CDSPageName: Text;
        BCPageName: Text;
        InitialSynchRecommendation: Text;
        InitialSynchRecommendationStyle: Text;
}

