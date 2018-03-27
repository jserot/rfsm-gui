/**********************************************************************/
/*                                                                    */
/*              This file is part of the RFSM package                 */
/*                                                                    */
/*  Copyright (c) 2018-present, Jocelyn SEROT.  All rights reserved.  */
/*                                                                    */
/*  This source code is licensed under the license found in the       */
/*  LICENSE file in the root directory of this source tree.           */
/*                                                                    */
/**********************************************************************/

#include "option.h"

AppOption::AppOption(QString _category, QString _name, Opt_type _typ, QString _desc) {
  category = _category;
  name = _name;
  typ = _typ;
  desc = _desc;
  switch ( typ ) {
  case UnitOpt:
    checkbox = new QCheckBox();
    val = NULL;
    break;
  case StringOpt:
    checkbox = NULL;
    val = new QLineEdit();
    //val->setFixedSize(100,20);
  case IntOpt:
    checkbox = NULL;
    val = new QLineEdit();
    //val->setFixedSize(100,20);
    break;
  }
}
