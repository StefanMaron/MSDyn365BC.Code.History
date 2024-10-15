tableextension 11780 "User Setup CZP" extends "User Setup"
{
    fields
    {
        field(11740; "Cash Resp. Ctr. Filter CZP"; Code[10])
        {
            Caption = 'Cash Responsibility Center Filter';
            TableRelation = "Responsibility Center";
            DataClassification = CustomerContent;
        }
        field(11742; "Cash Desk Amt. Appr. Limit CZP"; Integer)
        {
            BlankZero = true;
            Caption = 'Cash Desk Amt. Approval Limit';
            MinValue = 0;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                BothLimitErr: Label 'You cannot have both a %1 and %2.', Comment = '%1 = Approval Limit FieldCaption, %2 = Unlimited Approval FieldCaption';
            begin
                if "Unlimited Sales Approval" and ("Cash Desk Amt. Appr. Limit CZP" <> 0) then
                    Error(BothLimitErr, FieldCaption("Cash Desk Amt. Appr. Limit CZP"), FieldCaption("Unlimited Cash Desk Appr. CZP"));
            end;
        }
        field(11743; "Unlimited Cash Desk Appr. CZP"; Boolean)
        {
            Caption = 'Unlimited Cash Desk Approval';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Unlimited Cash Desk Appr. CZP" then
                    "Cash Desk Amt. Appr. Limit CZP" := 0;
            end;
        }
    }
}
