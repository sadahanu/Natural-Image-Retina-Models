#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Apr  6 13:33:00 2017

@author: zhouyu
"""
import matplotlib.pyplot as plt

def plotdiag(x,y,xer,yer,**kwargs):
    plt.errobar(x, y, xerr = xer, yerr = yer, fmt = 'o',**kwargs)
    xmin,xmax = plt.xlim()
    ymin,ymax = plt.ylim()
    axmin, axmax = min(xmin,ymin),max(xmax,ymax)
    plt.plot([axmin, axmax],[axmin, axmax],linestyle = ':')
