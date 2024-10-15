tableextension 18808 "Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(18807; "TCS Nature of Collection"; Code[10])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("TDS Section Code", '');
                TestField("TDS Certificate Receivable", false);
            end;
        }
        field(18808; "Pay TCS"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(18809; "T.C.A.N. No."; Code[10])
        {
            TableRelation = "T.C.A.N. No.";
            DataClassification = CustomerContent;
        }
        modify("TDS Section Code")
        {
            trigger OnAfterValidate()
            begin
                TestField("TCS Nature of Collection", '');
            end;
        }
        modify("TDS Certificate Receivable")
        {
            trigger OnAfterValidate()
            begin
                if "TDS Certificate Receivable" then
                    TestField("TCS Nature of Collection", '');
            end;
        }
    }
    procedure AllowedNOCLookup(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20])
    var
        AllowedNOC: Record "Allowed Noc";
        TCSNaturofCollection: Record "TCS Nature Of Collection";
    begin
        if "Account Type" = "Account Type"::Customer then begin
            TCSNaturofCollection.reset();
            AllowedNoc.Reset();
            AllowedNoc.SetRange("Customer No.", CustomerNo);
            if AllowedNoc.findset() then
                repeat
                    TCSNaturofCollection.SetRange(Code, AllowedNoc."TCS Nature of Collection");
                    if TCSNaturofCollection.FindFirst() then
                        TCSNaturofCollection.mark(true);
                until AllowedNoc.Next() = 0;
            TCSNaturofCollection.SetRange(code);
            TCSNaturofCollection.MarkedOnly(true);
            if PAGE.RunModal(0, TCSNaturofCollection) = ACTION::LookupOK then
                CheckDefaultandAssignNOC(GenJournalLine, TCSNaturofCollection.Code)
        end;
    end;

    local procedure CheckDefaultandAssignNOC(var GenJournalLine: Record "Gen. Journal Line"; NocType: code[10])
    var
        AllowedNOC: Record "Allowed Noc";
    begin
        AllowedNOC.Reset();
        AllowedNOC.SetRange("Customer No.", GenJournalLine."Account No.");
        AllowedNOC.SetRange("TCS Nature of Collection", NocType);
        if AllowedNOC.findfirst() then
            GenJournalLine.Validate("TCS Nature of Collection", AllowedNOC."TCS Nature of Collection")
        else
            ConfirmAssignNOC(GenJournalLine, NocType);
    end;

    local procedure ConfirmAssignNOC(var GenJournalLine: Record "Gen. Journal Line"; NocType: code[10])
    var
        AllowedNoc: Record "Allowed Noc";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmMessageMsg: label 'NOC Type %1 is not attached with Customer No. %2, Do you want to assign to customer & Continue ?', Comment = '%1= Noc Type, %2=Customer No..';
    begin
        if ConfirmManagement.GetResponseOrDefault
        (strSubstNo(ConfirmMessageMsg, NocType, GenJournalLine."Account No."), true)
        then begin
            AllowedNoc.init();
            AllowedNoc."TCS Nature of Collection" := NocType;
            AllowedNoc."Customer No." := GenJournalLine."Account No.";
            AllowedNoc.insert();
            GenJournalLine.Validate("TCS Nature of Collection", NocType);
        end;
    end;
}