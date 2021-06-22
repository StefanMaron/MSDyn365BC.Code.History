page 5134 "Contact Duplicates"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Duplicate Contacts';
    DataCaptionFields = "Contact No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Contact Duplicate";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the contact for which a duplicate has been found.';
                }
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact for which a duplicate has been found.';
                }
                field("Duplicate Contact No."; "Duplicate Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact number of the duplicate that was found.';
                }
                field("Duplicate Contact Name"; "Duplicate Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    DrillDownPageID = "Contact Card";
                    ToolTip = 'Specifies the name of the contact that has been identified as a possible duplicate.';
                }
                field("Separate Contacts"; "Separate Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the two contacts are not true duplicates, but separate contacts.';

                    trigger OnValidate()
                    begin
                        SeparateContactsOnAfterValidat;
                    end;
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GenerateDuplicateSearchString)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Generate Duplicate Search String';
                Image = CompareContacts;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a duplicate search string for contacts to be used when searching for duplicate contact entries.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Generate Dupl. Search String");
                end;
            }
            action(ContactDuplicateDetails)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'View';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View details of the contacts that were detected as duplicates.';

                trigger OnAction()
                var
                    ContactDuplicateDetails: Page "Contact Duplicate Details";
                begin
                    ContactDuplicateDetails.SetContactNo("Contact No.", "Duplicate Contact No.");
                    ContactDuplicateDetails.Run;
                end;
            }
        }
    }

    local procedure SeparateContactsOnAfterValidat()
    begin
        CurrPage.Update;
    end;
}

