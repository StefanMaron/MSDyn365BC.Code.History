namespace Microsoft.Finance.Deferral;

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
                SubPageLink = "Deferral Doc. Type" = field("Deferral Doc. Type"),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No."),
                              "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                              "Version No." = field("Version No.");
            }
        }
    }

    actions
    {
    }
}

