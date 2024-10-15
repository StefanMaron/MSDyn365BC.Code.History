page 31054 "Credit Proposal"
{
    Caption = 'Credit Proposal';
    InsertAllowed = false;
    PageType = Worksheet;

    layout
    {
        area(content)
        {
            group(Control1220007)
            {
                ShowCaption = false;
                field(SourceType; SourceType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Type';
                    OptionCaption = 'Customer,Vendor,Contact';
                    ToolTip = 'Specifies the source type';

                    trigger OnValidate()
                    begin
                        SourceTypeOnAfterValidate;
                    end;
                }
                field(SourceNo; SourceNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source No.';
                    ToolTip = 'Specifies the source number';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Cust: Record Customer;
                        Vend: Record Vendor;
                        Cont: Record Contact;
                    begin
                        case SourceType of
                            SourceType::Customer:
                                begin
                                    if Cust.Get(SourceNo) then;
                                    if PAGE.RunModal(0, Cust) = ACTION::LookupOK then begin
                                        SourceNo := Cust."No.";
                                        ApplyFilters;
                                    end;
                                end;
                            SourceType::Vendor:
                                begin
                                    if Vend.Get(SourceNo) then;
                                    if PAGE.RunModal(0, Vend) = ACTION::LookupOK then begin
                                        SourceNo := Vend."No.";
                                        ApplyFilters;
                                    end;
                                end;
                            SourceType::Contact:
                                begin
                                    if Cont.Get(SourceNo) then;
                                    Cont.SetRange(Type, Cont.Type::Company);
                                    if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                        SourceNo := Cont."No.";
                                        ApplyFilters;
                                    end;
                                end;
                        end;
                        SetName;
                    end;

                    trigger OnValidate()
                    begin
                        SourceNoOnAfterValidate;
                    end;
                }
                field(SourceName; SourceName)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies source No. for credit proposal lines';
                    ShowCaption = false;
                }
            }
            part(CustLedgEntries; "Cust. Ledg. Entries Subform")
            {
                ApplicationArea = Basic, Suite;
            }
            part(VendLedgEntries; "Vendor Ledg. Entries Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageView = SORTING("Vendor No.", "Posting Date", "Currency Code");
            }
            group(Control1220001)
            {
                ShowCaption = false;
                field(TotalBalance; TotalBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies total balance (LCY) of credit proposal';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Recount Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recount Balance';
                    Image = Recalculate;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Specifies recount balance';

                    trigger OnAction()
                    begin
                        TotalBalance := CurrPage.CustLedgEntries.PAGE.GetBalance + CurrPage.VendLedgEntries.PAGE.GetBalance;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if AppFilters then begin
            ApplyFilters;
            AppFilters := false;
        end;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        if SourceNo <> '' then begin
            AppFilters := true;
            SetName;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CreditsSetup: Record "Credits Setup";
        SourceType: Option Customer,Vendor,Contact;
        SourceNo: Code[20];
        TotalBalance: Decimal;
        SourceName: Text[100];
        SetupRead: Boolean;
        AppFilters: Boolean;

    [Scope('OnPrem')]
    procedure SetCreditHeader(var CreditHeader: Record "Credit Header")
    begin
        SourceType := CreditHeader.Type;
        SourceNo := CreditHeader."Company No.";
    end;

    [Scope('OnPrem')]
    procedure GetLedgEntries(var CustLedgEntry1: Record "Cust. Ledger Entry"; var VendLedgEntry1: Record "Vendor Ledger Entry")
    begin
        CustLedgEntry1.Copy(CustLedgEntry);
        VendLedgEntry1.Copy(VendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure ApplyFilters()
    var
        ContactBusRelation: Record "Contact Business Relation";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        Cust: Record Customer;
        Vend: Record Vendor;
        RecFilter: Text;
    begin
        GetSetup;
        case SourceType of
            SourceType::Customer:
                begin
                    Cust.Get(SourceNo);
                    Clear(RecFilter);
                    case CreditsSetup."Credit Proposal By" of
                        CreditsSetup."Credit Proposal By"::"Registration No.":
                            if Cust."Registration No." <> '' then begin
                                Vend.SetRange("Registration No.", Cust."Registration No.");
                                if Vend.FindSet(false) then begin
                                    repeat
                                        if RecFilter = '' then
                                            RecFilter := Vend."No."
                                        else
                                            RecFilter := RecFilter + '|' + Vend."No.";
                                    until Vend.Next = 0;
                                end;
                            end;
                        CreditsSetup."Credit Proposal By"::"Bussiness Relation":
                            begin
                                ContactBusRelation.SetCurrentKey("Link to Table", "No.");
                                ContactBusRelation.SetRange("Link to Table", ContactBusRelation."Link to Table"::Customer);
                                ContactBusRelation.SetRange("No.", SourceNo);
                                if ContactBusRelation.FindFirst then
                                    RecFilter := GetLedgEntryFilterFromCont(ContactBusRelation."Link to Table"::Vendor,
                                        ContactBusRelation."Contact No.");
                            end;
                    end;
                    Clear(CustLedgEntry1);
                    CustLedgEntry1.SetRange("Customer No.", Cust."No.");
                    Clear(VendLedgEntry1);
                    if (RecFilter = '') and CreditsSetup."Show Empty when not Found" then
                        VendLedgEntry1.SetRange("Entry No.", 1, -1)
                    else
                        VendLedgEntry1.SetFilter("Vendor No.", RecFilter);
                    CurrPage.CustLedgEntries.PAGE.ApplyFilters(CustLedgEntry1);
                    CurrPage.VendLedgEntries.PAGE.ApplyFilters(VendLedgEntry1);
                end;
            SourceType::Vendor:
                begin
                    Vend.Get(SourceNo);
                    Clear(RecFilter);
                    case CreditsSetup."Credit Proposal By" of
                        CreditsSetup."Credit Proposal By"::"Registration No.":
                            if Vend."Registration No." <> '' then begin
                                Cust.SetRange("Registration No.", Vend."Registration No.");
                                if Cust.FindSet(false, false) then begin
                                    repeat
                                        if RecFilter = '' then
                                            RecFilter := Cust."No."
                                        else
                                            RecFilter := RecFilter + '|' + Cust."No.";
                                    until Cust.Next = 0;
                                end;
                            end;
                        CreditsSetup."Credit Proposal By"::"Bussiness Relation":
                            begin
                                ContactBusRelation.SetCurrentKey("Link to Table", "No.");
                                ContactBusRelation.SetRange("Link to Table", ContactBusRelation."Link to Table"::Vendor);
                                ContactBusRelation.SetRange("No.", SourceNo);
                                if ContactBusRelation.FindFirst then
                                    RecFilter := GetLedgEntryFilterFromCont(ContactBusRelation."Link to Table"::Customer,
                                        ContactBusRelation."Contact No.");
                            end;
                    end;
                    Clear(VendLedgEntry1);
                    VendLedgEntry1.SetRange("Vendor No.", Vend."No.");
                    Clear(CustLedgEntry1);
                    if (RecFilter = '') and CreditsSetup."Show Empty when not Found" then
                        CustLedgEntry1.SetRange("Entry No.", 1, -1)
                    else
                        CustLedgEntry1.SetFilter("Customer No.", RecFilter);
                    CurrPage.CustLedgEntries.PAGE.ApplyFilters(CustLedgEntry1);
                    CurrPage.VendLedgEntries.PAGE.ApplyFilters(VendLedgEntry1);
                end;
            SourceType::Contact:
                begin
                    Clear(CustLedgEntry1);
                    RecFilter := GetLedgEntryFilterFromCont(ContactBusRelation."Link to Table"::Customer, SourceNo);
                    if (RecFilter = '') and CreditsSetup."Show Empty when not Found" then
                        CustLedgEntry1.SetRange("Entry No.", 1, -1)
                    else
                        CustLedgEntry1.SetFilter("Customer No.", RecFilter);
                    CurrPage.CustLedgEntries.PAGE.ApplyFilters(CustLedgEntry1);

                    Clear(VendLedgEntry1);
                    RecFilter := GetLedgEntryFilterFromCont(ContactBusRelation."Link to Table"::Vendor, SourceNo);
                    if (RecFilter = '') and CreditsSetup."Show Empty when not Found" then
                        VendLedgEntry1.SetRange("Entry No.", 1, -1)
                    else
                        VendLedgEntry1.SetFilter("Vendor No.", RecFilter);
                    CurrPage.VendLedgEntries.PAGE.ApplyFilters(VendLedgEntry1);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLedgEntryFilterFromCont(LinkToTable: Option; ContactNo: Code[20]) ValueFilter: Text[1024]
    var
        ContactBusRelation: Record "Contact Business Relation";
    begin
        ContactBusRelation.SetRange("Contact No.", ContactNo);
        ContactBusRelation.SetRange("Link to Table", LinkToTable);
        if ContactBusRelation.FindSet(false, false) then begin
            repeat
                if ValueFilter = '' then
                    ValueFilter := ContactBusRelation."No."
                else
                    ValueFilter := ValueFilter + '|' + ContactBusRelation."No.";
            until ContactBusRelation.Next = 0;
        end;
    end;

    local procedure SetName()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        Cont: Record Contact;
    begin
        Clear(SourceName);
        case SourceType of
            SourceType::Customer:
                begin
                    Cust.Get(SourceNo);
                    SourceName := Cust.Name;
                end;
            SourceType::Vendor:
                begin
                    Vend.Get(SourceNo);
                    SourceName := Vend.Name;
                end;
            SourceType::Contact:
                begin
                    Cont.Get(SourceNo);
                    SourceName := Cont.Name;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSetup()
    begin
        if not SetupRead then begin
            CreditsSetup.Get;
            SetupRead := true;
        end;
    end;

    local procedure SourceTypeOnAfterValidate()
    begin
        Clear(SourceNo);
        Clear(SourceName);
    end;

    local procedure SourceNoOnAfterValidate()
    begin
        ApplyFilters;
        SetName;
    end;

    local procedure LookupOKOnPush()
    begin
        Clear(CustLedgEntry);
        Clear(VendLedgEntry);
        CurrPage.CustLedgEntries.PAGE.GetEntries(CustLedgEntry);
        CurrPage.VendLedgEntries.PAGE.GetEntries(VendLedgEntry);
    end;
}

