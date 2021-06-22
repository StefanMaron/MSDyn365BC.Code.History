page 1704 "Deferral Schedule View"
{
    Caption = 'Deferral Schedule View';
    DataCaptionFields = "Start Date";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Posted Deferral Header";

    layout
    {
        area(content)
        {
            part("<Deferral Shedule View Subform>"; "Deferral Schedule View Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = FIELD("Deferral Doc. Type"),
                              "Gen. Jnl. Document No." = FIELD("Gen. Jnl. Document No."),
                              "Account No." = FIELD("Account No."),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
            }
        }
    }

    actions
    {
    }
}

