codeunit 1101 "CA Jnl.-Check Line"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        RunCheck(Rec);
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        Text000: Label 'Cost type or balance cost type must be defined.\Line %1, document %2, amount %3.';
        Text001: Label 'You cannot define both cost center and cost object.\Line %1, document %2, amount %3.';
        Text002: Label 'Balance cost center or balance cost object must be defined.\Line %1, document %2, amount %3.';
        Text003: Label 'You cannot define both balance cost center and balance cost object.\Line %1, document %2, amount %3.';
        Text004: Label 'Cost center or cost object must be defined. \Line %1, document %2, amount %3.';
        Text005: Label 'is not within the permitted range of posting dates', Comment = 'starts with "Posting Date"';

    procedure RunCheck(var CostJnlLine: Record "Cost Journal Line")
    var
        CostType: Record "Cost Type";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        IsHandled: Boolean;
    begin
        OnBeforeRunCheck(CostJnlLine);

        with CostJnlLine do begin
            TestField("Posting Date");
            TestField("Document No.");

            SourceCodeSetup.Get();
            TestField(Amount);

            if ("Cost Type No." = '') and ("Bal. Cost Type No." = '') then
                Error(Text000, "Line No.", "Document No.", Amount);

            if "Cost Type No." <> '' then begin
                CostType.Get("Cost Type No.");
                CostType.TestField(Blocked, false);
                CostType.TestField(Type, CostType.Type::"Cost Type");

                if "Source Code" <> SourceCodeSetup."G/L Entry to CA" then
                    if ("Cost Center Code" = '') and ("Cost Object Code" = '') then
                        Error(Text004, "Line No.", "Document No.", Amount);
                if ("Cost Center Code" <> '') and ("Cost Object Code" <> '') then
                    Error(Text001, "Line No.", "Document No.", Amount);
            end;

            if "Bal. Cost Type No." <> '' then begin
                CostType.Get("Bal. Cost Type No.");
                CostType.TestField(Blocked, false);
                CostType.TestField(Type, CostType.Type::"Cost Type");

                if ("Bal. Cost Center Code" = '') and ("Bal. Cost Object Code" = '') then
                    Error(Text002, "Line No.", "Document No.", Amount);
                if ("Bal. Cost Center Code" <> '') and ("Bal. Cost Object Code" <> '') then
                    Error(Text003, "Line No.", "Document No.", Amount);
            end;

            IsHandled := false;
            OnRunCheckOnBeforeDateNotAllowed(CostJnlLine, IsHandled);
            if not IsHandled then
                if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                    FieldError("Posting Date", Text005);
        end;

        OnAfterCheckCostJnlLine(CostJnlLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCostJnlLine(var CostJnlLine: Record "Cost Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var CostJnlLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeDateNotAllowed(var CostJnlLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

