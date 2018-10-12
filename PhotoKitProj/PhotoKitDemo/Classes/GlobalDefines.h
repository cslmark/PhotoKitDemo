//
//  GlobalDefines.h
//  iOSPhotoKit
//
//  Created by Iansl on 2018/10/10.
//  Copyright © 2018 Iansl. All rights reserved.
//

#ifndef GlobalDefines_h
#define GlobalDefines_h

#ifndef DECLARE_WEAK_SELF
#define DECLARE_WEAK_SELF __typeof(&*self) __weak weakSelf = self;
#endif

#ifndef DECLARE_STRONG_SELF
#define DECLARE_STRONG_SELF __typeof(&*self) __strong strongSelf = weakSelf;
#endif


#endif /* GlobalDefines_h */
