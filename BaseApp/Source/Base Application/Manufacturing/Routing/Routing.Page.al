namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;

page 99000766 Routing
{
    Caption = 'Routing';
    PageType = ListPlus;
    SourceTable = "Routing Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the routing header.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a search description.';
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series you want to use to create a new version of this routing.';
                }
                field(ActiveVersionCode; ActiveVersionCode)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Active Version';
                    Editable = false;
                    ToolTip = 'Specifies if the routing version is currently being used.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        RtngVersion: Record "Routing Version";
                    begin
                        RtngVersion.SetRange("Routing No.", Rec."No.");
                        RtngVersion.SetRange("Version Code", ActiveVersionCode);
                        PAGE.RunModal(PAGE::"Routing Version", RtngVersion);
                        ActiveVersionCode := VersionMgt.GetRtngVersion(Rec."No.", WorkDate(), true);
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the routing card was last modified.';

                    trigger OnValidate()
                    begin
                        LastDateModifiedOnAfterValidat();
                    end;
                }
            }
            part(RoutingLine; "Routing Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Routing No." = field("No."),
                              "Version Code" = const('');
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
            group("&Routing")
            {
                Caption = '&Routing';
                Image = Route;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = const("Routing Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Versions")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Versions';
                    Image = RoutingVersions;
                    RunObject = Page "Routing Version List";
                    RunPageLink = "Routing No." = field("No.");
                    ToolTip = 'View or edit other versions of the routing, typically with other operations data. ';
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    RunObject = Page "Where-Used Item List";
                    RunPageLink = "Routing No." = field("No.");
                    RunPageView = sorting("Routing No.");
                    ToolTip = 'View a list of BOMs in which the item is used.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy &Routing")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &Routing';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Copy an existing routing to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        FromRtngHeader: Record "Routing Header";
                    begin
                        Rec.TestField("No.");
                        if PAGE.RunModal(0, FromRtngHeader) = ACTION::LookupOK then
                            CopyRouting.CopyRouting(FromRtngHeader."No.", '', Rec, '');
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Routing Sheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routing Sheet';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Routing Sheet";
                ToolTip = 'View basic information for routings, such as send-ahead quantity, setup time, run time and time unit. This report shows you the operations to be performed in this routing, the work or machine centers to be used, the personnel, the tools, and the description of each operation.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Copy &Routing_Promoted"; "Copy &Routing")
                {
                }
                actionref("&Versions_Promoted"; "&Versions")
                {
                }
                actionref("Where-used_Promoted"; "Where-used")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActiveVersionCode :=
          VersionMgt.GetRtngVersion(Rec."No.", WorkDate(), true);
    end;

    var
        VersionMgt: Codeunit VersionManagement;
        CopyRouting: Codeunit "Routing Line-Copy Lines";
        ActiveVersionCode: Code[20];

    local procedure LastDateModifiedOnAfterValidat()
    begin
        CurrPage.Update();
    end;
}

