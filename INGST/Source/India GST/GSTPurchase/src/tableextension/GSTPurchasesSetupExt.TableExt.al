tableextension 18084 "GST Purchases Setup Ext" extends "Purchases & Payables Setup"
{
    fields
    {
        field(18080; "Posted Purch. Inv.(Unreg)";
        Code[10])
        {
            caption = 'Posted Purch. Inv.(Unreg)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18081; "Posted Purch Cr. Memo(Unreg)"; Code[10])
        {
            caption = 'Posted Purch Cr. Memo(Unreg)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18082; "Posted Purch Inv.(Unreg Supp)"; Code[10])
        {
            caption = 'Posted Purch Inv.(Unreg Supp)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18083; "Pst. Pur. Inv(Unreg. Deb.Note)"; Code[10])
        {
            caption = 'Pst. Pur. Inv(Unreg. Deb.Note)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18084; "GST Liability Adj. Jnl Nos."; Code[10])
        {
            caption = 'GST Liability Adj. Jnl Nos.';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18085; "Purch. Inv. Nos. (Reg)"; Code[10])
        {
            caption = 'Purch. Inv. Nos. (Reg)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18086; "Purch. Inv. Nos. (Reg Supp)"; Code[10])
        {
            caption = 'Purch. Inv. Nos. (Reg Supp)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18087; "Pur. Inv. Nos.(Reg Deb.Note)"; Code[10])
        {
            caption = 'Pur. Inv. Nos.(Reg Deb.Note)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18088; "Purch. Cr. Memo Nos. (Reg)"; Code[10])
        {
            caption = 'Purch. Cr. Memo Nos. (Reg)';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18089; "RCM Exempt Start Date (Unreg)"; date)
        {
            Caption = 'RCM Exempt Start Date (Unreg)';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                IF ("RCM Exempt Start Date (Unreg)" <> 0D) AND ("RCM Exempt End Date (Unreg)" <> 0D) THEN
                    IF "RCM Exempt Start Date (Unreg)" > "RCM Exempt End Date (Unreg)" THEN
                        ERROR(RcmBeforeDateErr);
            end;
        }
        field(18090; "RCM Exempt End Date (Unreg)"; date)
        {
            Caption = 'RCM Exempt End Date (Unreg)';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                IF "RCM Exempt End Date (Unreg)" < "RCM Exempt Start Date (Unreg)" THEN
                    ERROR(RcmAfterDateErr);
            end;
        }
    }
    var
        RcmBeforeDateErr: label 'RCM start date must be earlier then RCM End Date.';
        RcmAfterDateErr: label 'RCM End date must not be earlier then RCM start Date.';

}