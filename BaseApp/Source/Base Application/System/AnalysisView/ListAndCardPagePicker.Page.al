// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

using System.Reflection;
using System.Apps;

page 9641 "List and Card page picker"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Page Metadata";
    Caption = 'Choose a source page';
    Editable = false;
    ShowFilter = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ID; Rec.ID)
                {
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the page id.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the page name.';
                }
                field(PageType; Rec.PageType)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the page type.';
                }
                field(AppName; AppName)
                {
                    Caption = 'App Name';
                    ToolTip = 'Specifies the name of the app the page is declared in.';
                }
                field(AppPublisher; AppPublisher)
                {
                    Caption = 'App Publisher';
                    ToolTip = 'Specifies the publisher of the app the page is declared in.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter(PageType, '%1|%2', Rec.PageType::List, Rec.PageType::Card);
    end;

    trigger OnAfterGetRecord()
    var
        AllObj: Record AllObj;
        PublishedApplication: Record "Published Application";
    begin
        if AllObj.ReadPermission() and AllObj.Get(AllObj."Object Type"::Page, Rec.ID) then
            if PublishedApplication.ReadPermission() and PublishedApplication.Get(AllObj."App Runtime Package ID") then begin
                AppName := PublishedApplication.Name;
                AppPublisher := PublishedApplication.Publisher;
                exit;
            end;
    end;

    var
        AppName: Text[250];
        AppPublisher: Text[250];
}