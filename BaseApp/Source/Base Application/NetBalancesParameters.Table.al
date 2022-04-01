table 109 "Net Balances Parameters"
{
    Caption = 'Net Balances Parameters';
    Tabletype = Temporary;

    fields
    {
        field(1; ID; Code[20])
        {
            Caption = 'ID';
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            trigger OnValidate()
            begin
                IF "Document No." <> '' THEN
                    IF IncStr("Document No.") = '' THEN
                        error(DocNoMustContainNumberErr);
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(6; "Order of Suggestion"; Enum "Net Cust/Vend Balances Order")
        {
            Caption = 'Order of Suggestion';
        }
        field(7; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(8; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
    }

    keys
    {
        key(PK; ID) { }
    }

    var
        DocNoMustContainNumberErr: Label 'Document No. must contain a number.';
        DescriptionMsg: Label 'Net customer/vendor balances %1 %2', Comment = '%1 %2';
        PostingDateErr: Label 'Please enter the Posting Date.';
        DocumentNoErr: Label 'Please enter the Document No.';

    procedure Initialize()
    begin
        IF "Posting Date" = 0D THEN
            "Posting Date" := WorkDate();
        Description := CopyStr(DescriptionMsg, 1, MaxStrLen(Description));
    end;

    procedure Verify()
    begin
        IF "Posting Date" = 0D THEN
            error(PostingDateErr);

        IF "Document No." = '' THEN
            error(DocumentNoErr);
    end;

}