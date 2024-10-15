tableextension 18015 "GST Sales Rec Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(18000; "GST Dependency Type"; Enum "GST Dependency Type")
        {
            Caption = 'GST Dependency Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18001; "Posted Inv. Nos. (Exempt)"; code[10])
        {
            caption = 'Posted Inv. Nos. (Exempt)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                if not ("GST Dependency Type" in [
                    "GST Dependency Type"::"Bill-to Address",
                    "GST Dependency Type"::"Ship-to Address"])
                then
                    error(GSTDependencyErr);
            end;
        }
        field(18002; "Posted Cr. Memo Nos. (Exempt)"; code[10])
        {
            caption = 'Posted Cr. Memo Nos. (Exempt)';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(18003; "Posted Inv. No. (Export)"; code[10])
        {
            caption = 'Posted Inv. No. (Export)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18004; "Posted Cr. Memo No. (Export)"; code[10])
        {
            caption = 'Posted Cr. Memo No. (Export)';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(18005; "Posted Inv. No. (Supp)"; code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            caption = 'Posted Inv. No. (Supp)';
            TableRelation = "No. Series";
        }
        field(18006; "Posted Cr. Memo No. (Supp)"; code[10])
        {
            caption = 'Posted Cr. Memo No. (Supp)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18007; "Posted Inv. No. (Debit Note)"; code[10])
        {
            caption = 'Posted Inv. No. (Debit Note)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18008; "Posted Inv. No. (Non-GST)"; code[10])
        {
            caption = 'Posted Inv. No. (Non-GST)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18009; "Posted Cr. Memo No. (Non-GST)"; code[10])
        {
            caption = 'Posted Cr. Memo No. (Non-GST)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    var
        GSTDependencyErr: Label 'GST Dependency Type must be Bill-To Address Or Ship-To Address.';
}