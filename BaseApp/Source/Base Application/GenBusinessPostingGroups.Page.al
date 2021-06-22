page 312 "Gen. Business Posting Groups"
{
    AdditionalSearchTerms = 'posting setup,general business posting group';
    ApplicationArea = Basic, Suite;
    Caption = 'Gen. Business Posting Groups';
    PageType = List;
    SourceTable = "Gen. Business Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the business group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the general business posting group.';
                }
                field("Def. VAT Bus. Posting Group"; "Def. VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a default VAT business group code.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Def. VAT Bus. Posting Group" <> xRec."Def. VAT Bus. Posting Group" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text000, Code, xRec."Def. VAT Bus. Posting Group"), true)
                            then
                                Error('');
                    end;
                }
                field("Auto Insert Default"; "Auto Insert Default")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to automatically insert the Def. VAT Bus. Posting Group when the corresponding Code is inserted on new customer and vendor cards.';
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
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "General Posting Setup";
                RunPageLink = "Gen. Bus. Posting Group" = FIELD(Code);
                ToolTip = 'View or edit how you want to set up combinations of general business and general product posting groups.';
            }
        }
    }

    var
        Text000: Label 'This will change all occurrences of VAT Bus. Posting Group in G/L Account, Customer, and Vendor tables\where Gen. Bus. Posting Group is %1\and VAT Bus. Posting Group is %2. Are you sure that you want to continue?';
}

