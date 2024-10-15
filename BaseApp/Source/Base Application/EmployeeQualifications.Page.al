page 5206 "Employee Qualifications"
{
    AutoSplitKey = true;
    Caption = 'Employee Qualifications';
    DataCaptionFields = "Person No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Employee Qualification";
    SourceTableView = WHERE("Qualification Type" = CONST(Education));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Qualification Code"; "Qualification Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a qualification code for the employee.';
                }
                field("From Date"; "From Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the employee started working on obtaining this qualification.';
                }
                field("To Date"; "To Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the employee is considered to have obtained this qualification.';
                }
                field(Type; Type)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a type for the qualification, which specifies where the qualification was obtained.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description of the qualification.';
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the qualification on this line expires.';
                    Visible = false;
                }
                field("Institution/Company"; "Institution/Company")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the institution from which the employee obtained the qualification.';
                }
                field(Cost; Cost)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the cost of the qualification.';
                    Visible = false;
                }
                field("Course Grade"; "Course Grade")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the grade that the employee received for the course, specified by the qualification on this line.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Series"; "Document Series")
                {
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Kind of Education"; "Kind of Education")
                {
                }
                field("Form of Education"; "Form of Education")
                {
                }
                field("Type of Education"; "Type of Education")
                {
                }
                field("Organization Address"; "Organization Address")
                {
                }
                field("Faculty Name"; "Faculty Name")
                {
                }
                field(Speciality; Speciality)
                {
                }
                field("Science Degree"; "Science Degree")
                {
                }
                field("Language Code"; "Language Code")
                {
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Language Proficiency"; "Language Proficiency")
                {
                }
                field("Qualification Type"; "Qualification Type")
                {
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies whether a comment was entered for this entry.';
                }
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Q&ualification")
            {
                Caption = 'Q&ualification';
                Image = Certificate;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Employee Qualification"),
                                  "No." = FIELD("Person No."),
                                  "Table Line No." = FIELD("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action23)
                {
                }
                action("Q&ualification Overview")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Q&ualification Overview';
                    Image = QualificationOverview;
                    RunObject = Page "Qualification Overview";
                    ToolTip = 'View qualifications that are registered for the employee.';
                }
            }
        }
    }
}

