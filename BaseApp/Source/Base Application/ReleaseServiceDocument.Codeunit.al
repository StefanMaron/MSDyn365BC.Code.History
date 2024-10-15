codeunit 416 "Release Service Document"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        ServiceHeader.Copy(Rec);
        Code;
        Rec := ServiceHeader;
    end;

    var
        Text001: Label 'There is nothing to release for %1 %2.', Comment = 'Example: There is nothing to release for Order 12345.';
        ServiceHeader: Record "Service Header";
        InvtSetup: Record "Inventory Setup";
        WhseServiceRelease: Codeunit "Whse.-Service Release";

    local procedure "Code"()
    var
        ServLine: Record "Service Line";
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        with ServiceHeader do begin
            if "Release Status" = "Release Status"::"Released to Ship" then
                exit;

            OnBeforeReleaseServiceDoc(ServiceHeader);

            if "Document Type" = "Document Type"::Quote then
                TestField("Bill-to Customer No.");
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "No.");
            ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
            ServLine.SetFilter(Quantity, '<>0');
            if ServLine.IsEmpty then
                Error(Text001, "Document Type", "No.");
            InvtSetup.Get;
            if InvtSetup."Location Mandatory" then begin
                ServLine.SetCurrentKey(Type);
                ServLine.SetRange(Type, ServLine.Type::Item);
                if ServLine.FindSet then
                    repeat
                        ServLine.TestField("Location Code");
                    until ServLine.Next = 0;
                ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
            end;

            OnCodeOnAfterCheck(ServiceHeader, ServLine);

            ServLine.Reset;
            Validate("Release Status", "Release Status"::"Released to Ship");
            ServLine.SetServHeader(ServiceHeader);
            ServLine.CalcVATAmountLines(0, ServiceHeader, ServLine, TempVATAmountLine0, ServLine.IsShipment);
            ServLine.CalcVATAmountLines(1, ServiceHeader, ServLine, TempVATAmountLine1, ServLine.IsShipment);
            ServLine.UpdateVATOnLines(0, ServiceHeader, ServLine, TempVATAmountLine0);
            ServLine.UpdateVATOnLines(1, ServiceHeader, ServLine, TempVATAmountLine1);
            Modify(true);

            if "Document Type" = "Document Type"::Order then
                WhseServiceRelease.Release(ServiceHeader);

            OnAfterReleaseServiceDoc(ServiceHeader);
        end;
    end;

    procedure Reopen(var ServHeader: Record "Service Header")
    begin
        with ServHeader do begin
            if "Release Status" = "Release Status"::Open then
                exit;

            OnBeforeReopenServiceDoc(ServHeader);
            Validate("Release Status", "Release Status"::Open);
            Modify(true);
            if "Document Type" in ["Document Type"::Order] then
                WhseServiceRelease.Reopen(ServHeader);
            OnAfterReopenServiceDoc(ServHeader);
        end;
    end;

    procedure PerformManualRelease(var ServHeader: Record "Service Header")
    begin
        OnBeforePerformManualRelease(ServHeader);

        CODEUNIT.Run(CODEUNIT::"Release Service Document", ServHeader);

        OnAfterPerformManualRelease(ServHeader);
    end;

    procedure PerformManualReopen(var ServHeader: Record "Service Header")
    begin
        Reopen(ServHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;
}

