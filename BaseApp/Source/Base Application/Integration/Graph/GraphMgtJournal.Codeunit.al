codeunit 5482 "Graph Mgt - Journal"
{

    trigger OnRun()
    begin
    end;

    procedure GetDefaultJournalLinesTemplateName(): Text[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PAGE::"General Journal");
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, 0);
        GenJnlTemplate.FindFirst();
        exit(GenJnlTemplate.Name);
    end;

    procedure GetDefaultCustomerPaymentsTemplateName(): Text[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PAGE::"Cash Receipt Journal");
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, 3);
        GenJnlTemplate.FindFirst();
        exit(GenJnlTemplate.Name);
    end;

    procedure GetDefaultVendorPaymentsTemplateName(): Text[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PAGE::"Payment Journal");
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, 4);
        GenJnlTemplate.FindFirst();
        exit(GenJnlTemplate.Name);
    end;
}

