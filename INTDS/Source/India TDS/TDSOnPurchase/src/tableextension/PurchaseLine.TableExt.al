tableextension 18716 "Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(18716; "TDS Section Code"; Code[10])
        {
            Caption = 'TDS Section Code';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                TDSSection: Record "TDS Section";

            begin
                if "TDS Section Code" <> '' then
                    if not TDSSection.Get("TDS Section Code") then
                        Error(SectionErr, TDSSection, TDSSection.TableCaption());
            end;
        }
        field(18717; "Nature of Remittance"; Code[10])
        {
            Caption = 'Nature of Remittance';
            TableRelation = "TDS Nature of Remittance";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18718; "Act Applicable"; Code[10])
        {
            Caption = 'Act Applicable';
            TableRelation = "Act Applicable";
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    procedure OnAfterTDSSectionCodeLookupPurchLine(var PurchLine: Record "Purchase Line"; VendorNo: Code[20]; SetTDSSection: boolean)
    var
        Section: Record "TDS Section";
        AllowedSections: Record "Allowed Sections";
    begin
        if PurchLine."Document Type" IN [PurchLine."Document Type"::Order, PurchLine."Document Type"::Invoice] then begin
            AllowedSections.Reset();
            AllowedSections.SetRange("Vendor No", VendorNo);
            if AllowedSections.FindSet() then
                repeat
                    section.setrange(code, AllowedSections."TDS Section");
                    if Section.FindFirst() then
                        Section.Mark(true);
                until AllowedSections.Next() = 0;
            Section.setrange(code);
            section.MarkedOnly(true);
            if page.RunModal(Page::"TDS Sections", Section) = Action::LookupOK then
                checkDefaultandAssignTDSSection(PurchLine, Section.Code, SetTDSSection);
        end;
    end;

    procedure CheckDefaultAndAssignTDSSection(var PurchLine: Record "Purchase Line"; TDSSection: Code[10]; SetTDSSection: boolean)
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.Reset();
        AllowedSections.SetRange("Vendor No", PurchLine."Buy-from Vendor No.");
        AllowedSections.SetRange("TDS Section", TDSSection);
        if AllowedSections.findfirst() then
            if SetTDSSection then
                PurchLine.Validate("TDS Section Code", AllowedSections."TDS Section")
            else
                PurchLine.Validate("Work Tax Nature Of Deduction", AllowedSections."TDS Section")
        else
            ConfirmAssignTDSSection(PurchLine, TDSSection, SetTDSSection);
    end;

    local procedure ConfirmAssignTDSSection(var PurchLine: Record "Purchase Line"; TDSSection: code[10]; SetTDSSection: boolean)
    var
        AllowedSections: Record "Allowed Sections";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(strSubstNo(ConfirmMessageMsg, TDSSection, PurchLine."Buy-from Vendor No."), true) then begin
            AllowedSections.init();
            AllowedSections."TDS Section" := TDSSection;
            AllowedSections."Vendor No" := PurchLine."Buy-from Vendor No.";
            AllowedSections.insert();
            if SetTDSSection then
                PurchLine."TDS Section Code" := TDSSection
            else
                PurchLine.Validate("Work Tax Nature Of Deduction", AllowedSections."TDS Section")
        end;
    end;

    procedure CheckNonResidentsPaymentSelection()
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.Reset();
        AllowedSections.SetRange("Vendor No", "Buy-from Vendor No.");
        AllowedSections.SetRange("TDS Section", "TDS Section Code");
        AllowedSections.SetRange("Non Resident Payments", true);
        if AllowedSections.IsEmpty then
            Error(NonResidentPaymentsSelectionErr, Rec."Buy-from Vendor No.");
    end;

    var
        SectionErr: Label '%1 does not exist in table %2.', Comment = '%1 = TDS Section Code, %2= Table Name';
        NonResidentPaymentsSelectionErr: Label 'Non Resident Payments is not selected for Vendor No. %1', Comment = '%1 is Vendor No.';
        ConfirmMessageMsg: label 'TDS Section Code %1 is not attached with Vendor No. %2, Do you want to assign to vendor & Continue ?', Comment = '%1= TDS Section Code ,%2= Vendor No.';
}