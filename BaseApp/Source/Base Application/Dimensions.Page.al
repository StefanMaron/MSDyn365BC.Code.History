page 536 Dimensions
{
    ApplicationArea = Dimensions;
    Caption = 'Dimensions';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Dimension';
    SourceTable = Dimension;
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
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the dimension code.';
                }
                field("Code Caption"; "Code Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the caption of the dimension code. This is displayed as the name of dimension code fields.';
                }
                field("Filter Caption"; "Filter Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the caption of the dimension code when used as a filter. This is displayed as the name of dimension filter fields.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a description of the dimension code.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to IC Dimension Code"; "Map-to IC Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which intercompany dimension corresponds to the dimension on the line.';
                    Visible = false;
                }
                field("Consolidation Code"; "Consolidation Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code that is used for consolidation.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Dimension")
            {
                Caption = '&Dimension';
                Image = Dimensions;
                action("Dimension &Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimension &Values';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Dimension Values";
                    RunPageLink = "Dimension Code" = FIELD(Code);
                    ToolTip = 'View or edit the dimension values for the current dimension.';
                }
                action("Account Type De&fault Dim.")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Account Type De&fault Dim.';
                    Image = DefaultDimension;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Account Type Default Dim.";
                    RunPageLink = "Dimension Code" = FIELD(Code),
                                  "No." = CONST('');
                    ToolTip = 'Specify default dimension settings for the relevant account types such as customers, vendors, or items. For example, you can make a dimension required.';
                }
                action(Translations)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Translations';
                    Image = Translations;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Dimension Translations";
                    RunPageLink = Code = FIELD(Code);
                    ToolTip = 'View or edit translated dimensions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(MapToICDimWithSameCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Map to IC Dim. with Same Code';
                    Image = MapDimensions;
                    ToolTip = 'Specify which intercompany dimension corresponds to the dimension on the line. When you enter a dimension code on an intercompany sales or purchase line, the program will put the corresponding intercompany dimension code on the line that is sent to your intercompany partner.';

                    trigger OnAction()
                    var
                        Dimension: Record Dimension;
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        CurrPage.SetSelectionFilter(Dimension);
                        if Dimension.Find('-') and Confirm(Text000) then
                            repeat
                                ICMapping.MapOutgoingICDimensions(Dimension);
                            until Dimension.Next = 0;
                    end;
                }
            }
        }
    }

    var
        Text000: Label 'Are you sure you want to map the selected lines?';
}

