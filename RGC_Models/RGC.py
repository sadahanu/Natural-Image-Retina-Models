#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Apr  6 12:08:50 2017

@author: zhouyu
"""
from RGC_Models.Utils import plotdiag
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
class RGC(object):
    def __init__(self,cellid):
        self.cellID = cellid

    def getGratings(self,grating):
        cols = ['RecType','stimulusTag','currentAbsContrast','currentMeanLevel',
                'backgroundIntensity','rfSigmaCenter','MeanRespOn','SEM']
        temp = grating[cols]
        f_cols = cols.drop(['MeanRespOn','SEM','stimulusTag'])
        temp_grate = temp[temp.stimulusTag == 'grating']
        temp_grate.rename(columns = {'MeanRespOn':'grate_Mean','SEM':'grate_SEM'},inplace = True)
        temp_disc = temp[temp.stimulusTag == 'intensity']
        temp_disc.rename(columns = {'MeanRespOn':'disc_Mean','SEM':'disc_SEM'},inplace = True)
        Gratings = pd.merge(temp_grate,temp_disc,on = list(f_cols))
        Gratings.drop(['stimulusTag_x','stimulusTag_y'],axis = 1, inplace = True)
        Gratings['abs_BarWidth'] = np.absolute(Gratings['currentBarWidth'])
        Gratings.rename(columns = {'currentMeanLevel':'meanLevel'}, inplace = True)
        self.Gratings = Gratings
        
    def getContrastCurve(self, contrast):
        cols = ['RecType','currentSpotContrast','backgroundIntensity',
                'MeanRespOn','SEM']
        temp = contrast[cols]
        temp.rename(columns = {'backgroundIntensity':'background',
                               'currentSpotContrast':'Contrast'}, inplace = True)
        self.Contrast = temp
        
    def getImgPatch(self, patchResp):
        cols = ['RecType','imageName','currentPatchLocation','equivalentIntensity',
                'backgroundIntensity','MeanRespOn','SEM','rfSigmaCenter']
        temp = patchResp[cols]
        f_cols = cols.drop(['MeanRespOn','SEM','stimulusTag'])
        temp_img = temp[temp.stimulusTag == 'grating']
        temp_img.rename(columns = {'MeanRespOn':'img_Mean','SEM':'img_SEM'},inplace = True)
        temp_disc = temp[temp.stimulusTag == 'intensity']
        temp_disc.rename(columns = {'MeanRespOn':'disc_Mean','SEM':'disc_SEM'},inplace = True)
        Patches = pd.merge(temp_img,temp_disc,on = list(f_cols))
        Patches.drop(['stimulusTag_x','stimulusTag_y'],axis = 1, inplace = True)
        self.ImgPatch = Patches
        
    def getTexture(self, textures):
        cols = ['RecType','seed','contrast','background','centerSigma','rotation'
                'MeanRespOn','SEM']
        self.Textures = textures[cols]
    
    def plotGratings(self):
        print "Grating responses measured at the background of :"
        print self.Gratings.backgroundIntensity.unique()
        g = sns.FacetGrid(self.Gratings, row="RecType",col="meanLevel", hue = "abs_BarWidth",sharex=False, sharey=False)
        g = (g.map(plotdiag, "grate_Mean","disc_Mean","grate_SEM","disc_SEM", edgecolor="w").add_legend())
    
    def plotTextures(self):
        g = sns.FacetGrid(self.Textures, row="centerSigma",col="seed", hue = "RecType")
        g = (g.map(plt.errorbar,"rotation","MeanRespOn","SEM").add_legend())
    
    def plotContrast(self):
        g = sns.FacetGrid(self.Contrast,col = "RecType", col_wrap = 3,hue = "background",
                          sharex = False, sharey = False)
        g = (g.map(plt.errorbar,"Contrast","MeanRespOn","SEM").add_legend())
        
    def plotImgPatches(self):
        print "Img responses measured for images:"
        print self.ImgPatches.imageName.unique()
        g = sns.FacetGrid(self.ImgPatches, row="RecType",col="imageName",sharex=False, sharey=False)
        g = g.map(plotdiag, "img_Mean", "disc_Mean","img_SEM","disc_SEM", edgecolor="w")