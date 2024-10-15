tableextension 31328 "Purchase Header CZ" extends "Purchase Header"
{
    fields
    {
        field(31305; "Physical Transfer CZ"; Boolean)
        {
            Caption = 'Physical Transfer';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Physical Transfer CZ" then
                    if not IsCreditDocType() then
                        FieldError("Document Type");
                Validate("Transaction Type", GetDefaultTransactionType());
                UpdatePurchLinesByFieldNo(FieldNo("Physical Transfer CZ"), CurrFieldNo <> 0);
            end;
        }
        field(31310; "Intrastat Exclude CZ"; Boolean)
        {
            Caption = 'Intrastat Exclude';
            DataClassification = CustomerContent;
        }
    }

    trigger OnBeforeInsert()
    begin
        "Physical Transfer CZ" := IntrastatReportSetup.GetDefaultPhysicalTransferCZ() and IsCreditDocType();
    end;

    var
        IntrastatReportSetup: Record "Intrastat Report Setup";
        IntrastatReportManagementCZ: Codeunit IntrastatReportManagementCZ;

    procedure CheckIntrastatMandatoryFieldsCZ()
    begin
        if not (Ship or Receive) then
            exit;
        if IsIntrastatTransactionCZL() and ShipOrReceiveInventoriableTypeItemsCZL() then begin
            IntrastatReportSetup.Get();
            if IntrastatReportSetup."Transaction Type Mandatory CZ" then
                TestField("Transaction Type");
            if IntrastatReportSetup."Transaction Spec. Mandatory CZ" then
                TestField("Transaction Specification");
            if IntrastatReportSetup."Transport Method Mandatory CZ" then
                TestField("Transport Method");
            if IntrastatReportSetup."Shipment Method Mandatory CZ" then
                TestField("Shipment Method Code");
        end;
    end;

    procedure GetPartnerBasedOnSetupCZ() Vendor: Record Vendor
    begin
        exit(IntrastatReportManagementCZ.GetVendorBasedOnSetup("Buy-from Vendor No.", "Pay-to Vendor No."));
    end;

    local procedure GetDefaultTransactionType(): Code[10]
    begin
        exit(IntrastatReportManagementCZ.GetDefaultTransactionType(Rec));
    end;
}