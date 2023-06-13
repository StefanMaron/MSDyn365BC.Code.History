codeunit 416 "Release Service Document"
{
    TableNo = "Service Header";
    Permissions = TableData "Service Header" = rm,
                  TableData "Service Line" = r;

    trigger OnRun()
    begin
        ServiceHeader.Copy(Rec);
        ServiceHeader.SetHideValidationDialog(Rec.GetHideValidationDialog());
        Code();
        Rec := ServiceHeader;
    end;

    var
        NothingToReleaseErr: Label 'There is nothing to release for %1 %2.', Comment = 'Example: There is nothing to release for Order 12345.';
        ServiceHeader: Record "Service Header";
        InvtSetup: Record "Inventory Setup";
        WhseServiceRelease: Codeunit "Whse.-Service Release";
        SkipWhseRequestOperations: Boolean;

    local procedure "Code"()
    var
        ServLine: Record "Service Line";
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        IsHandled: Boolean;
    begin
        with ServiceHeader do begin
            if "Release Status" = "Release Status"::"Released to Ship" then
                exit;

            OnBeforeReleaseServiceDoc(ServiceHeader);

            if "Document Type" = "Document Type"::Quote then
                TestField("Bill-to Customer No.");

            IsHandled := FALSE;
            OnBeforeNothingToReleaseErr(ServiceHeader, IsHandled);
            if not IsHandled then begin
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "No.");
                ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
                ServLine.SetFilter(Quantity, '<>0');
                if ServLine.IsEmpty() then
                    Error(NothingToReleaseErr, "Document Type", "No.");
            end;

            InvtSetup.Get();
            if InvtSetup."Location Mandatory" then begin
                ServLine.SetCurrentKey(Type);
                ServLine.SetRange(Type, ServLine.Type::Item);
                ServLine.SetRange("Location Code", '');
                if ServLine.FindSet() then
                    repeat
                        VerifyLocationCode(ServLine);
                    until ServLine.Next() = 0;
                ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
            end;

            OnCodeOnAfterCheck(ServiceHeader, ServLine);

            ServLine.Reset();
            Validate("Release Status", "Release Status"::"Released to Ship");
            ServLine.SetServHeader(ServiceHeader);
            ServLine.CalcVATAmountLines(0, ServiceHeader, ServLine, TempVATAmountLine0, ServLine.IsShipment());
            ServLine.CalcVATAmountLines(1, ServiceHeader, ServLine, TempVATAmountLine1, ServLine.IsShipment());
            ServLine.UpdateVATOnLines(0, ServiceHeader, ServLine, TempVATAmountLine0);
            ServLine.UpdateVATOnLines(1, ServiceHeader, ServLine, TempVATAmountLine1);
            Modify(true);

            if "Document Type" = "Document Type"::Order then
                if not SkipWhseRequestOperations then
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
                if not SkipWhseRequestOperations then
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
        OnBeforePerformManualReopen(ServHeader);
        Reopen(ServHeader);
    end;

    local procedure VerifyLocationCode(var ServLine: Record "Service Line")
    var
        Item: Record Item;
    begin
        if ServLine."No." <> '' then
            if Item.Get(ServLine."No.") then
                if Item.Type = Item.Type::"Non-Inventory" then
                    exit;

        ServLine.TestField("Location Code");
    end;

    internal procedure SetSkipWhseRequestOperations(NewSkipWhseRequestOperations: Boolean)
    begin
        SkipWhseRequestOperations := NewSkipWhseRequestOperations;
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
    local procedure OnBeforeNothingToReleaseErr(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualReopen(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;
}

