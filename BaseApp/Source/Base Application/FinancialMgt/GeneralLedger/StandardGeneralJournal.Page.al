page 751 "Standard General Journal"
{
    Caption = 'Standard General Journal';
    PageType = ListPlus;
    SourceTable = "Standard General Journal";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code to identify the standard general journal that you are about to save.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text that indicates the purpose of the standard general journal.';
                }
            }
            part(StdGenJnlLines; "Standard Gen. Journal Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "Standard Journal Code" = FIELD(Code);
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if xRec.Code = '' then
            SetRange(Code, Code);
    end;
}

