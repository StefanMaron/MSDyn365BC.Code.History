tableextension 18840 "Sales Line" extends "Sales Line"
{
    fields
    {
        field(18838; "TCS Nature of Collection"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18839; "Assessee Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }
    procedure AllowedNOCLookup(var salesLine: Record "sales line"; CustomerNo: Code[20])
    var
        AllowedNOC: Record "Allowed NOC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
    begin
        TCSNatureOfCollection.reset();
        AllowedNOC.Reset();
        AllowedNOC.SetRange("Customer No.", CustomerNo);
        if AllowedNOC.findset() then
            repeat
                TCSNatureOfCollection.SetRange(Code, AllowedNOC."TCS Nature of Collection");
                if TCSNatureOfCollection.FindFirst() then
                    TCSNatureOfCollection.mark(true);
            until AllowedNOC.Next() = 0;
        TCSNatureOfCollection.SetRange(code);
        TCSNatureOfCollection.MarkedOnly(true);
        if PAGE.RunModal(Page::"TCS Nature Of Collections", TCSNatureOfCollection) = ACTION::LookupOK then
            checkDefaultandAssignNoc(salesLine, TCSNatureOfCollection.Code)
    end;

    local procedure CheckDefaultandAssignNOC(var SalesLine: Record "sales line"; NocType: code[10])
    var
        AllowedNOC: Record "Allowed Noc";
    begin
        AllowedNOC.Reset();
        AllowedNOC.SetRange("Customer No.", SalesLine."Sell-to Customer No.");
        AllowedNOC.SetRange("TCS Nature of Collection", NocType);
        if AllowedNOC.findfirst() then
            SalesLine.Validate("TCS Nature of Collection", AllowedNOC."TCS Nature of Collection")
        else
            ConfirmAssignNOC(SalesLine, NocType);
    end;

    local procedure ConfirmAssignNOC(var SalesLine: Record "sales line"; NOCType: code[10])
    var
        AllowedNOC: Record "Allowed NOC";
        ConfirmManagement: Codeunit "Confirm Management";
        NOCConfirmMsg: label 'NOC Type %1 is not attached with Customer No. %2, Do you want to assign to customer & Continue ?', Comment = '%1=Noc Type., %2=Customer No.';
    begin
        if ConfirmManagement.GetResponseOrDefault
        (strSubstNo(NOCConfirmMsg, NOCType, SalesLine."Sell-to Customer No."), true)
        then begin
            AllowedNOC.init();
            AllowedNOC."TCS Nature of Collection" := NOCType;
            AllowedNOC."Customer No." := SalesLine."Sell-to Customer No.";
            AllowedNOC.insert();
            SalesLine.Validate("TCS Nature of Collection", NOCType);
        end;
    end;
}
