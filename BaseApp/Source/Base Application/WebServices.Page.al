page 810 "Web Services"
{
    AdditionalSearchTerms = 'flow,odata,soap';
    ApplicationArea = Basic, Suite;
    Caption = 'Web Services';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Web Service Aggregate";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1102601000)
            {
                ShowCaption = false;
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the ID of the object.';
                    ValuesAllowed = Codeunit, Page, Query;
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    TableRelation = AllObj."Object ID" WHERE("Object Type" = FIELD("Object Type"));
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(ObjectName; WebServiceManagement.GetObjectCaption(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the object that will be exposed to the web service.';
                }
                field("Service Name"; "Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the service.';
                }
                field("All Tenants"; "All Tenants")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsWebServiceWriteable;
                    Enabled = IsWebServiceWriteable;
                    ToolTip = 'Specifies that the service is available to all tenants.';
                }
                field(Published; Published)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the web service is published. A published web service is available on the Business Central Server computer that you were connected to when you published. The web service is available across all Business Central Server instances running on the server computer.';
                }
                field(ODataV4Url; WebServiceManagement.GetWebServiceUrl(Rec, ClientType::ODataV4))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OData V4 URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL that is generated for the web service. You can test the web service immediately by choosing the link in the field.';
                }
                field(ODataUrl; WebServiceManagement.GetWebServiceUrl(Rec, ClientType::ODataV3))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OData URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL that is generated for the web service. You can test the web service immediately by choosing the link in the field.';
                }
                field(SOAPUrl; WebServiceManagement.GetWebServiceUrl(Rec, ClientType::SOAP))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SOAP URL';
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL that is generated for the web service. You can test the web service immediately by choosing the link in the field.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("<Reload>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reload';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Update the window with the latest information.';

                trigger OnAction()
                begin
                    WebServiceManagement.LoadRecords(Rec);
                end;
            }
            action("Create Data Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Data Set';
                Image = AddAction;
                RunObject = Page "OData Setup Wizard";
                ToolTip = 'Launches wizard to create data sets that can be used for building reports in Excel, Power BI or any other reporting tool that works with an OData data source.';
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "All Tenants" := IsWebServiceWriteable;
    end;

    trigger OnOpenPage()
    var
        WebService: Record "Web Service";
    begin
        if WebService.WritePermission() then
            IsWebServiceWriteable := true;
        WebServiceManagement.LoadRecords(Rec);
    end;

    var
        WebServiceManagement: Codeunit "Web Service Management";
        ClientType: Enum "Client Type";
        IsWebServiceWriteable: Boolean;
}

