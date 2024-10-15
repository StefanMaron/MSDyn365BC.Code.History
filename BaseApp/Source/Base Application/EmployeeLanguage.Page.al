page 17356 "Employee Language"
{
    AutoSplitKey = true;
    Caption = 'Employee Language';
    DataCaptionFields = "Person No.";
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Employee Qualification";
    SourceTableView = WHERE("Qualification Type" = CONST(Language));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Language Proficiency"; "Language Proficiency")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Institution/Company"; "Institution/Company")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Course Grade"; "Course Grade")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Series"; "Document Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
            }
        }
    }

    actions
    {
    }
}

