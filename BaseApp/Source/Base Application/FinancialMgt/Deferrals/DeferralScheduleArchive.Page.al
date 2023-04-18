page 1706 "Deferral Schedule Archive"
{
    Caption = 'Deferral Schedule Archive';
    DataCaptionFields = "Schedule Description";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Deferral Header Archive";

    layout
    {
        area(content)
        {
            part("<Deferral Sched. Arch. Subform>"; "Deferral Sched. Arch. Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = FIELD("Deferral Doc. Type"),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No."),
                              "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence"),
                              "Version No." = FIELD("Version No.");
            }
        }
    }

    actions
    {
    }
}

