page 9174 "All Objects with Caption"
{
    Caption = 'All Objects with Caption';
    Editable = false;
    PageType = List;
    SourceTable = AllObjWithCaption;

    layout
    {
        area(content)
        {
            repeater(Control1102601000)
            {
                ShowCaption = false;
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = All;
                    Caption = 'Object Type';
                    ToolTip = 'Specifies the type of the object.';
                    Visible = VisibleObjType;
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'Object ID';
                    ToolTip = 'Specifies the ID of the object.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Object Name';
                    ToolTip = 'Specifies the name of the object.';
                }
                field("Object Caption"; "Object Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Object Caption';
                    ToolTip = 'Specifies the caption of the object, that is, the name that will be displayed in the user interface.';
                    Visible = false;
                }
                field("Object Subtype"; "Object Subtype")
                {
                    ApplicationArea = All;
                    Caption = 'Object Subtype';
                    ToolTip = 'Specifies the subtype of the object.';
                    Visible = VisibleObjType;
                }
                field("App Name"; AppName)
                {
                    ApplicationArea = All;
                    Caption = 'App Name';
                    ToolTip = 'Specifies the App (extension) that provides this object.';
                    Visible = VisibleAppName;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        NavAppTable: Record "NAV App";
    begin
        VisibleObjType := true;
        VisibleAppName := NavAppTable.ReadPermission();
    end;

    trigger OnAfterGetRecord()
    var
        NavAppTable: Record "NAV App";
    begin
        if NavAppTable.ReadPermission() then
            if NavAppTable.Get("App Package ID") then
                AppName := NavAppTable.Name;
    end;

    var
        VisibleObjType: Boolean;
        VisibleAppName: Boolean;
        AppName: Text;

    procedure IsObjectTypeVisible(Visible: Boolean)
    begin
        VisibleObjType := Visible;
    end;
}

