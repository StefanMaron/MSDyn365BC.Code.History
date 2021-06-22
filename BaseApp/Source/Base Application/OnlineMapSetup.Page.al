page 800 "Online Map Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Online Map Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Online Map Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(TermsOfUseLbl; TermsOfUseLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Terms of Use';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        HyperLink('http://go.microsoft.com/fwlink/?LinkID=248686');
                    end;
                }
                field(PrivacyStatementLbl; PrivacyStatementLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Privacy Statement';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        HyperLink('http://go.microsoft.com/fwlink/?LinkID=248686');
                    end;
                }
            }
            group(Settings)
            {
                Caption = 'Settings';
                field("Map Parameter Setup Code"; "Map Parameter Setup Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Online Map Parameter Setup";
                    ToolTip = 'Specifies the map parameter code that is set up in the Online Map Parameter Setup window.';
                }
                field("Distance In"; "Distance In")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Distance in';
                    ToolTip = 'Specifies if distances in your online map should be shown in miles or kilometers.';
                }
                field(Route; Route)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Route (Quickest/Shortest)';
                    ToolTip = 'Specifies whether to use the quickest or shortest route for calculation.';
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
            action("&Parameter Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Parameter Setup';
                Image = EditList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Online Map Parameter Setup";
                ToolTip = 'Define which online map will be displayed when you call a map from a card, and what language will be used in maps and route directions.';
            }
        }
    }

    trigger OnOpenPage()
    var
        OnlineMapMgt: Codeunit "Online Map Management";
    begin
        Reset;
        if not Get then begin
            OnlineMapMgt.SetupDefault;
            Get;
        end;
    end;

    var
        TermsOfUseLbl: Label 'Microsoft Bing Maps Services Agreement.';
        PrivacyStatementLbl: Label 'Microsoft Bing Maps Privacy Statement.';
}

