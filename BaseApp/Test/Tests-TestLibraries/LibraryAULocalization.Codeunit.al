codeunit 143000 "Library - AU Localization"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure EnableGSTSetup(EnableGST: Boolean; FullGSTOnPrepayment: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        with GLSetup do begin
            Get();
            Validate("Enable GST (Australia)", EnableGST);
            Validate("Full GST on Prepayment", FullGSTOnPrepayment);
            Validate("GST Report", EnableGST);
            if EnableGST then
                Validate("Adjustment Mandatory", false);
            Modify(true);
        end;
    end;
}

