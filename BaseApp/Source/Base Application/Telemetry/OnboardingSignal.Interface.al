// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

interface "Onboarding Signal"
{
    Access = Public;

    /// <summary>
    /// Should check whether the onboarding criteria has been met.
    /// </summary>
    /// <returns> True if the onboarding criteria has been met. </returns>
    procedure IsOnboarded(): Boolean

}
