codeunit 3055 DotNet_GroupCollection
{

    trigger OnRun()
    begin
    end;

    var
        DotNetGroupCollection: DotNet GroupCollection;

    procedure "Count"(): Integer
    begin
        exit(DotNetGroupCollection.Count);
    end;

    procedure Item(GroupNumber: Integer; var DotNet_Group: Codeunit DotNet_Group)
    var
        DotNetGroup: DotNet Group;
    begin
        DotNetGroup := DotNetGroupCollection.Item(GroupNumber);
        DotNet_Group.SetGroup(DotNetGroup);
    end;

    procedure ItemGroupName(GroupName: Text; var DotNet_Group: Codeunit DotNet_Group)
    var
        DotNetGroup: DotNet Group;
    begin
        DotNetGroup := DotNetGroupCollection.Item(GroupName);
        DotNet_Group.SetGroup(DotNetGroup);
    end;

    procedure CopyTo(var DotNet_Array: Codeunit DotNet_Array; Index: Integer)
    var
        DotNetArray: DotNet Array;
    begin
        DotNetGroupCollection.CopyTo(DotNetArray, Index);
        DotNet_Array.SetArray(DotNetArray);
    end;

    procedure Equals(var DotNet_GroupCollection: Codeunit DotNet_GroupCollection): Boolean
    var
        DotNetGroups: DotNet GroupCollection;
    begin
        DotNet_GroupCollection.GetGroupCollection(DotNetGroups);
        exit(DotNetGroupCollection.Equals(DotNetGroups));
    end;

    procedure GetHashCode(): Integer
    begin
        exit(DotNetGroupCollection.GetHashCode());
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetGroupCollection));
    end;

    [Scope('OnPrem')]
    procedure GetGroupCollection(var DotNetGroupCollection2: DotNet GroupCollection)
    begin
        DotNetGroupCollection2 := DotNetGroupCollection;
    end;

    [Scope('OnPrem')]
    procedure SetGroupCollection(var DotNetGroupCollection2: DotNet GroupCollection)
    begin
        DotNetGroupCollection := DotNetGroupCollection2;
    end;
}

